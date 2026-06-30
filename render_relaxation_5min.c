#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define SR 44100
#define DURATION 300
#define TOTAL ((int64_t)SR * DURATION)
#define PI 3.14159265358979323846

static double clampd(double x, double lo, double hi) {
    return x < lo ? lo : (x > hi ? hi : x);
}

static double smoothstep(double x) {
    x = clampd(x, 0.0, 1.0);
    return x * x * (3.0 - 2.0 * x);
}

static double qfreq(double hz) {
    return round(hz * DURATION) / DURATION;
}

static void pan_stereo(double value, double pan, double *l, double *r) {
    *l += value * cos((pan + 1.0) * PI / 4.0);
    *r += value * sin((pan + 1.0) * PI / 4.0);
}

static void write_le16(FILE *f, uint16_t v) {
    fputc(v & 255, f);
    fputc((v >> 8) & 255, f);
}

static void write_le32(FILE *f, uint32_t v) {
    fputc(v & 255, f);
    fputc((v >> 8) & 255, f);
    fputc((v >> 16) & 255, f);
    fputc((v >> 24) & 255, f);
}

static uint32_t rng_state = 975318642u;
static double rand_bipolar(void) {
    rng_state = 1664525u * rng_state + 1013904223u;
    return ((double)(rng_state >> 8) / 16777215.0) * 2.0 - 1.0;
}

static double one_pole(double input, double *state, double amount) {
    *state += (input - *state) * amount;
    return *state;
}

static double soft_pulse(double phase, double width) {
    double d = phase < 1.0 - phase ? phase : 1.0 - phase;
    return exp(-((d / width) * (d / width)));
}

int main(void) {
    const char *out = "Fordybelse_relaxation_warm_5min.wav";
    int16_t *audio = (int16_t *)malloc((size_t)TOTAL * 2 * sizeof(int16_t));
    if (!audio) {
        fprintf(stderr, "Could not allocate render buffer.\n");
        return 1;
    }

    const double bpm = 72.0;
    const double beat_hz = bpm / 60.0;
    const double chords[5][6] = {
        {130.81, 164.81, 196.00, 261.63, 329.63, 392.00}, /* Cmaj9 */
        {110.00, 146.83, 174.61, 220.00, 293.66, 349.23}, /* Am11 */
        {98.00, 146.83, 196.00, 246.94, 293.66, 392.00},  /* G6/9 */
        {116.54, 146.83, 174.61, 233.08, 293.66, 349.23}, /* Bbmaj6 color */
        {130.81, 164.81, 196.00, 246.94, 329.63, 392.00}  /* Cmaj7 add6 */
    };
    const double roots[5] = {65.41, 55.00, 49.00, 58.27, 65.41};
    const double sparse_notes[8] = {261.63, 293.66, 329.63, 392.00, 349.23, 293.66, 246.94, 329.63};

    double pad_phase[5][6][2] = {{{0}}};
    double string_phase[5][3] = {{0}};
    double key_phase[3] = {0.2, 1.7, 2.8};
    double bass_phase = 0.0;
    double air_lp = 0.0, air_hp_state = 0.0, perc_state = 0.0;
    double delay_l[18000] = {0}, delay_r[24000] = {0};
    int dl = 0, dr = 0;

    for (int64_t n = 0; n < TOTAL; n++) {
        double t = (double)n / SR;
        double l = 0.0, r = 0.0;

        double beat = t * beat_hz;
        double bar = beat / 4.0;
        double phrase = bar / 8.0;
        int ci = ((int)floor(phrase)) % 5;
        int cj = (ci + 1) % 5;
        double cf = smoothstep(phrase - floor(phrase));
        double wa = 0.5 + 0.5 * cos(PI * cf);
        double wb = 0.5 - 0.5 * cos(PI * cf);

        double master = smoothstep(t / 10.0) * (1.0 - smoothstep((t - (DURATION - 10.0)) / 10.0));
        double breathe = 0.78 + 0.065 * sin(2 * PI * t / 75.0) + 0.030 * sin(2 * PI * t / 100.0);
        double phrase_breath = 0.58 + 0.42 * pow(sin(PI * fmod(t / 24.0, 1.0)), 0.82);

        /* Warm ambient pad bed. */
        for (int c = 0; c < 5; c++) {
            double weight = c == ci ? wa : (c == cj ? wb : 0.0);
            if (weight <= 0.000001) continue;
            for (int note = 0; note < 6; note++) {
                for (int layer = 0; layer < 2; layer++) {
                    double mul = layer == 0 ? 0.5 : 1.0;
                    double amp = layer == 0 ? 0.017 : 0.023;
                    double period = 75.0 + note * 12.5 + layer * 25.0;
                    double detune = 1.0 + 0.0009 * sin(2 * PI * t / period + c * 0.4 + note);
                    double hz = qfreq(chords[c][note] * mul);
                    pad_phase[c][note][layer] += 2 * PI * hz * detune / SR;
                    if (pad_phase[c][note][layer] > 2 * PI) pad_phase[c][note][layer] = fmod(pad_phase[c][note][layer], 2 * PI);
                    double ph = pad_phase[c][note][layer];
                    double tone = sin(ph) + 0.10 * sin(2.0 * ph + 0.35);
                    double pan = 0.34 * sin(2 * PI * t / (125.0 + note * 10.0) + c * 0.2);
                    pan_stereo(tone * amp * weight * breathe * phrase_breath, pan, &l, &r);
                }
            }
        }

        /* Gentle string-like sustained layer, synthetic and soft. */
        for (int c = 0; c < 5; c++) {
            double weight = c == ci ? wa : (c == cj ? wb : 0.0);
            if (weight <= 0.000001) continue;
            for (int v = 0; v < 3; v++) {
                double hz = qfreq(chords[c][v + 2] * 1.5);
                string_phase[c][v] += 2 * PI * hz / SR;
                if (string_phase[c][v] > 2 * PI) string_phase[c][v] -= 2 * PI;
                double bow = sin(string_phase[c][v]) + 0.06 * sin(3.0 * string_phase[c][v]);
                double amp = 0.0065 * weight * phrase_breath * (0.7 + 0.3 * sin(2 * PI * t / (60.0 + v * 20.0)));
                pan_stereo(bow * amp, -0.42 + v * 0.42, &l, &r);
            }
        }

        /* Slow, rounded low support. */
        double root_hz = qfreq(roots[ci] * wa + roots[cj] * wb);
        bass_phase += 2 * PI * root_hz / SR;
        if (bass_phase > 2 * PI) bass_phase -= 2 * PI;
        double whole_phase = fmod(beat / 4.0, 1.0);
        double bass_env = 0.62 + 0.38 * soft_pulse(whole_phase, 0.24);
        double bass = (sin(bass_phase) + 0.12 * sin(2.0 * bass_phase)) * 0.032 * bass_env;
        pan_stereo(bass, 0.0, &l, &r);

        /* Muted piano/key gestures: sparse, slow, non-hooky. */
        double key_cycle = fmod(beat / 2.0, 16.0);
        int key_step = (int)floor(key_cycle);
        if (key_step == 0 || key_step == 6 || key_step == 11) {
            double local = key_cycle - key_step;
            double env = pow(sin(PI * local), 3.4);
            int base_i = (ci + key_step) % 8;
            for (int k = 0; k < 3; k++) {
                double hz = qfreq(sparse_notes[(base_i + k * 2) % 8] * (k == 2 ? 0.5 : 1.0));
                key_phase[k] += 2 * PI * hz / SR;
                if (key_phase[k] > 2 * PI) key_phase[k] -= 2 * PI;
                double tone = sin(key_phase[k]) + 0.08 * sin(2.0 * key_phase[k]);
                double amp = (k == 2 ? 0.010 : 0.014) * env;
                pan_stereo(tone * amp, -0.22 + k * 0.22, &l, &r);
            }
        }

        /* Quiet, optional nature-like softness: abstract filtered air, no events. */
        double nse = rand_bipolar();
        double air = one_pole(nse, &air_lp, 0.0016);
        double hp = nse - one_pole(nse, &air_hp_state, 0.04);
        pan_stereo(air * 0.026 + hp * 0.0025, 0.18 * sin(2 * PI * t / 90.0), &l, &r);

        /* Slow predictable pulse, closer to breathing than percussion. */
        double beat_phase = fmod(beat, 1.0);
        double pulse = soft_pulse(beat_phase, 0.15) * 0.0045 + soft_pulse(fmod(beat / 2.0, 1.0), 0.20) * 0.0055;
        double muted_tick = one_pole(rand_bipolar() * pulse, &perc_state, 0.11);
        pan_stereo(muted_tick, 0.03, &l, &r);

        /* Soft delay wash for continuity. */
        double wet_l = delay_l[dl];
        double wet_r = delay_r[dr];
        delay_l[dl] = (l + wet_r * 0.16) * 0.20;
        delay_r[dr] = (r + wet_l * 0.16) * 0.20;
        dl = (dl + 1) % 18000;
        dr = (dr + 1) % 24000;
        l += wet_l * 0.15;
        r += wet_r * 0.15;

        l = tanh(l * 1.18) * 0.72 * master;
        r = tanh(r * 1.18) * 0.72 * master;
        audio[n * 2] = (int16_t)(clampd(l, -1.0, 1.0) * 32767.0);
        audio[n * 2 + 1] = (int16_t)(clampd(r, -1.0, 1.0) * 32767.0);
    }

    FILE *fout = fopen(out, "wb");
    if (!fout) {
        perror(out);
        free(audio);
        return 1;
    }
    uint32_t data_bytes = (uint32_t)(TOTAL * 2 * sizeof(int16_t));
    fwrite("RIFF", 1, 4, fout);
    write_le32(fout, 36 + data_bytes);
    fwrite("WAVEfmt ", 1, 8, fout);
    write_le32(fout, 16);
    write_le16(fout, 1);
    write_le16(fout, 2);
    write_le32(fout, SR);
    write_le32(fout, SR * 2 * 2);
    write_le16(fout, 4);
    write_le16(fout, 16);
    fwrite("data", 1, 4, fout);
    write_le32(fout, data_bytes);
    fwrite(audio, sizeof(int16_t), (size_t)TOTAL * 2, fout);
    fclose(fout);

    fprintf(stderr, "wrote %s\n", out);
    free(audio);
    return 0;
}

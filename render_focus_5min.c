#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define SR 44100
#define DURATION 1800
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

static uint32_t rng_state = 246813579u;
static double rand_bipolar(void) {
    rng_state = 1664525u * rng_state + 1013904223u;
    return ((double)(rng_state >> 8) / 16777215.0) * 2.0 - 1.0;
}

static double pulse_env(double beat_phase, double center, double width) {
    double d = fabs(beat_phase - center);
    if (d > 0.5) d = 1.0 - d;
    return exp(-((d / width) * (d / width)));
}

static double one_pole(double input, double *state, double amount) {
    *state += (input - *state) * amount;
    return *state;
}

int main(void) {
    const char *out = "Fordybelse_focus_downtempo_30min.wav";
    int16_t *audio = (int16_t *)malloc((size_t)TOTAL * 2 * sizeof(int16_t));
    if (!audio) {
        fprintf(stderr, "Could not allocate render buffer.\n");
        return 1;
    }

    const double bpm = 96.0;
    const double beat_hz = bpm / 60.0;
    const double chords[4][5] = {
        {130.81, 196.00, 261.63, 329.63, 392.00}, /* Cmaj9 color */
        {146.83, 220.00, 293.66, 349.23, 440.00}, /* Dm11 */
        {123.47, 196.00, 246.94, 311.13, 392.00}, /* Bm7b5 soft */
        {110.00, 164.81, 220.00, 277.18, 329.63}  /* Am / C */
    };
    const double bass_roots[4] = {65.41, 73.42, 61.74, 55.00};
    const double key_notes[6] = {261.63, 293.66, 329.63, 392.00, 440.00, 329.63};

    double pad_phase[4][5][2] = {{{0}}};
    double key_phase = 0.0, bass_phase = 0.0, hat_state = 0.0, noise_state = 0.0, perc_state = 0.0;
    double delay_l[12000] = {0}, delay_r[16000] = {0};
    int dl = 0, dr = 0;

    for (int64_t n = 0; n < TOTAL; n++) {
        double t = (double)n / SR;
        double l = 0.0, r = 0.0;

        double beat = t * beat_hz;
        double bar = beat / 4.0;
        int ci = ((int)floor(bar / 8.0)) % 4;
        double cf = smoothstep(fmod(bar / 8.0, 1.0));
        int cj = (ci + 1) % 4;
        double wa = 0.5 + 0.5 * cos(PI * cf);
        double wb = 0.5 - 0.5 * cos(PI * cf);
        double beat_phase = fmod(beat, 1.0);
        double half_phase = fmod(beat * 0.5, 1.0);
        double whole_phase = fmod(beat * 0.25, 1.0);

        double master = smoothstep(t / 10.0) * (1.0 - smoothstep((t - (DURATION - 10.0)) / 10.0));
        double session_energy = 0.88 + 0.12 * sin(2 * PI * t / 900.0 - PI / 2.0);
        double breathe = 0.80 + 0.05 * sin(2 * PI * t / 75.0) + 0.030 * sin(2 * PI * t / 50.0);
        double phrase_breath = 0.56 + 0.44 * pow(sin(PI * fmod(beat / 8.0, 1.0)), 0.72);

        for (int c = 0; c < 4; c++) {
            double weight = c == ci ? wa : (c == cj ? wb : 0.0);
            if (weight <= 0.000001) continue;
            for (int note = 0; note < 5; note++) {
                for (int layer = 0; layer < 2; layer++) {
                    double mul = layer == 0 ? 0.5 : 1.0;
                    double amp = layer == 0 ? 0.020 : 0.029;
                    double detune = 1.0 + 0.0011 * sin(2 * PI * t / (60.0 + note * 7.5 + layer * 9.0) + c);
                    double hz = qfreq(chords[c][note] * mul);
                    pad_phase[c][note][layer] += 2 * PI * hz * detune / SR;
                    if (pad_phase[c][note][layer] > 2 * PI) pad_phase[c][note][layer] = fmod(pad_phase[c][note][layer], 2 * PI);
                    double ph = pad_phase[c][note][layer];
                    double tone = sin(ph) + 0.12 * sin(2.0 * ph + 0.2);
                    double pan = 0.36 * sin(2 * PI * t / (90.0 + note * 12.0) + note);
                    pan_stereo(tone * amp * weight * breathe * phrase_breath * session_energy, pan, &l, &r);
                }
            }
        }

        /* Gentle bass pulse: stable and rounded, no heavy transient. */
        double bass_hz = qfreq(bass_roots[ci] * wa + bass_roots[cj] * wb);
        bass_phase += 2 * PI * bass_hz / SR;
        if (bass_phase > 2 * PI) bass_phase -= 2 * PI;
        double bass_env = 0.58 + 0.42 * pulse_env(whole_phase, 0.03, 0.18);
        double bass = (sin(bass_phase) + 0.2 * sin(2.0 * bass_phase)) * 0.044 * bass_env * (0.92 + 0.08 * session_energy);
        pan_stereo(bass, 0.0, &l, &r);

        /* Muted keys: sparse, soft, and intentionally unhooky. */
        double key_gate = 0.0;
        double key_step_pos = fmod(t * beat_hz / 2.0, 12.0);
        int key_step = (int)floor(key_step_pos);
        if (key_step == 0 || key_step == 5 || key_step == 9) {
            double local = key_step_pos - key_step;
            key_gate = pow(sin(PI * local), 3.2) * 0.022;
        }
        if (key_gate > 0.0) {
            int note_i = (key_step + ci) % 6;
            key_phase += 2 * PI * qfreq(key_notes[note_i]) / SR;
            if (key_phase > 2 * PI) key_phase -= 2 * PI;
            double key = sin(key_phase) * key_gate;
            pan_stereo(key, -0.18 + 0.1 * sin(2 * PI * t / 40.0), &l, &r);
        }

        /* Light percussion and soft noise bed, filtered and low level. */
        double noise = rand_bipolar();
        double soft_noise = one_pole(noise, &noise_state, 0.0025);
        double hat_noise = noise - one_pole(noise, &hat_state, 0.08);
        double hat_env = 0.0055 * pulse_env(half_phase, 0.02, 0.045) * (0.85 + 0.15 * session_energy);
        double perc_env = (0.008 * pulse_env(beat_phase, 0.04, 0.07) + 0.004 * pulse_env(beat_phase, 0.54, 0.07)) * (0.85 + 0.15 * session_energy);
        double perc = one_pole(hat_noise * perc_env, &perc_state, 0.2);
        pan_stereo(soft_noise * 0.030, 0.18 * sin(2 * PI * t / 65.0), &l, &r);
        pan_stereo(perc + hat_noise * hat_env, 0.06, &l, &r);

        /* Tiny delay blur on keys/percussion energy for softness. */
        double wet_l = delay_l[dl];
        double wet_r = delay_r[dr];
        delay_l[dl] = (l + wet_r * 0.18) * 0.22;
        delay_r[dr] = (r + wet_l * 0.18) * 0.22;
        dl = (dl + 1) % 12000;
        dr = (dr + 1) % 16000;
        l += wet_l * 0.12;
        r += wet_r * 0.12;

        l = tanh(l * 1.25) * 0.78 * master;
        r = tanh(r * 1.25) * 0.78 * master;
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

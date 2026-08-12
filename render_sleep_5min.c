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

static uint32_t rng_state = 135792468u;
static double rand_bipolar(void) {
    rng_state = 1664525u * rng_state + 1013904223u;
    return ((double)(rng_state >> 8) / 16777215.0) * 2.0 - 1.0;
}

static double one_pole(double input, double *state, double amount) {
    *state += (input - *state) * amount;
    return *state;
}

int main(void) {
    const char *out = "Fordybelse_sleep_drift_30min.wav";
    int16_t *audio = (int16_t *)malloc((size_t)TOTAL * 2 * sizeof(int16_t));
    if (!audio) {
        fprintf(stderr, "Could not allocate render buffer.\n");
        return 1;
    }

    const double chords[4][6] = {
        {98.00, 130.81, 164.81, 196.00, 261.63, 329.63},  /* C over G */
        {87.31, 110.00, 146.83, 174.61, 220.00, 293.66},  /* Am/F warmth */
        {82.41, 123.47, 164.81, 196.00, 246.94, 329.63},  /* Em/C soft */
        {98.00, 123.47, 146.83, 196.00, 246.94, 293.66}   /* G/D return */
    };
    const double low_roots[4] = {49.00, 43.65, 41.20, 49.00};

    double pad_phase[4][6][3] = {{{0}}};
    double low_phase[4] = {0};
    double key_phase[2] = {0.4, 1.9};
    double air_lp1 = 0.0, air_lp2 = 0.0, air_l = 0.0, air_r = 0.0;
    double delay_l[30000] = {0}, delay_r[36000] = {0};
    int dl = 0, dr = 0;

    for (int64_t n = 0; n < TOTAL; n++) {
        double t = (double)n / SR;
        double l = 0.0, r = 0.0;

        double phrase = t / 75.0;
        int ci = ((int)floor(phrase)) % 4;
        int cj = (ci + 1) % 4;
        double cf = smoothstep(phrase - floor(phrase));
        double wa = 0.5 + 0.5 * cos(PI * cf);
        double wb = 0.5 - 0.5 * cos(PI * cf);

        double master = smoothstep(t / 24.0) * (1.0 - smoothstep((t - (DURATION - 24.0)) / 24.0));
        double session_dim = 1.0 - 0.10 * smoothstep(t / DURATION);
        double breath = 0.74 + 0.040 * sin(2 * PI * t / 96.0) + 0.020 * sin(2 * PI * t / 150.0);
        double drowsy_taper = 1.0 - 0.12 * smoothstep(t / DURATION);
        double phrase_breath = 0.60 + 0.40 * pow(sin(PI * fmod(t / 32.0, 1.0)), 0.86);

        /* Very soft drone/pad bed, slow and non-eventful. */
        for (int c = 0; c < 4; c++) {
            double weight = c == ci ? wa : (c == cj ? wb : 0.0);
            if (weight <= 0.000001) continue;
            for (int note = 0; note < 6; note++) {
                for (int layer = 0; layer < 3; layer++) {
                    double mul = layer == 0 ? 0.5 : (layer == 1 ? 1.0 : 1.5);
                    double amp = layer == 0 ? 0.014 : (layer == 1 ? 0.018 : 0.0045);
                    double period = 120.0 + note * 18.0 + layer * 40.0;
                    double detune = 1.0 + 0.00055 * sin(2 * PI * t / period + c * 0.31 + note * 0.2);
                    double hz = qfreq(chords[c][note] * mul);
                    pad_phase[c][note][layer] += 2 * PI * hz * detune / SR;
                    if (pad_phase[c][note][layer] > 2 * PI) pad_phase[c][note][layer] = fmod(pad_phase[c][note][layer], 2 * PI);
                    double ph = pad_phase[c][note][layer];
                    double tone = sin(ph) + 0.055 * sin(2.0 * ph + 0.15);
                    double pan = 0.24 * sin(2 * PI * t / (170.0 + note * 20.0) + c * 0.1);
                    pan_stereo(tone * amp * weight * breath * drowsy_taper * phrase_breath * session_dim, pan, &l, &r);
                }
            }
        }

        /* Warm low support, no bass pressure or pulse. */
        for (int c = 0; c < 4; c++) {
            double weight = c == ci ? wa : (c == cj ? wb : 0.0);
            if (weight <= 0.000001) continue;
            low_phase[c] += 2 * PI * qfreq(low_roots[c]) / SR;
            if (low_phase[c] > 2 * PI) low_phase[c] -= 2 * PI;
            double low = sin(low_phase[c]) * 0.012 * weight * phrase_breath * session_dim * (0.9 + 0.1 * sin(2 * PI * t / 130.0));
            pan_stereo(low, 0.0, &l, &r);
        }

        /* Rare muted key tones, blurred enough not to become a motif. */
        double key_window = fmod(t, 55.0);
        if (key_window > 8.0 && key_window < 14.5) {
            double env = pow(sin(PI * ((key_window - 8.0) / 6.5)), 2.4);
            double note_a = qfreq(chords[ci][3]);
            double note_b = qfreq(chords[ci][4] * 0.5);
            key_phase[0] += 2 * PI * note_a / SR;
            key_phase[1] += 2 * PI * note_b / SR;
            if (key_phase[0] > 2 * PI) key_phase[0] -= 2 * PI;
            if (key_phase[1] > 2 * PI) key_phase[1] -= 2 * PI;
            pan_stereo(sin(key_phase[0]) * env * 0.0034 * session_dim, -0.12, &l, &r);
            pan_stereo(sin(key_phase[1]) * env * 0.0025 * session_dim, 0.16, &l, &r);
        }

        /* Subtle room-tone style bed: abstract filtered air, no identifiable events. */
        double noise = rand_bipolar();
        double low_noise = one_pole(noise, &air_lp1, 0.00075);
        double mid_noise = one_pole(low_noise, &air_lp2, 0.004);
        air_l = one_pole(mid_noise + 0.1 * rand_bipolar(), &air_l, 0.0012);
        air_r = one_pole(mid_noise + 0.1 * rand_bipolar(), &air_r, 0.0011);
        l += air_l * 0.018;
        r += air_r * 0.018;

        /* Long, quiet delay wash to remove edges and keep continuity. */
        double wet_l = delay_l[dl];
        double wet_r = delay_r[dr];
        delay_l[dl] = (l + wet_r * 0.12) * 0.18;
        delay_r[dr] = (r + wet_l * 0.12) * 0.18;
        dl = (dl + 1) % 30000;
        dr = (dr + 1) % 36000;
        l += wet_l * 0.18;
        r += wet_r * 0.18;

        l = tanh(l * 1.10) * 0.62 * master;
        r = tanh(r * 1.10) * 0.62 * master;
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

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

static double pulse_env(double t, double period, double width, double phase) {
    double x = fmod(t / period + phase, 1.0);
    if (x < 0) x += 1.0;
    double d = x < 1.0 - x ? x : 1.0 - x;
    return exp(-((d / width) * (d / width)));
}

static double motif_gate(double t) {
    double window = fmod(t, 225.0) / 225.0;
    if (window < 0.18) {
        return smoothstep(window / 0.05) * (1.0 - smoothstep((window - 0.13) / 0.05));
    }
    if (window > 0.58 && window < 0.70) {
        double local = (window - 0.58) / 0.12;
        return 0.55 * pow(sin(PI * local), 2.0);
    }
    return 0.0;
}

int main(void) {
    const char *out = "Fordybelse_focus_ambient_30min_loop.wav";
    int16_t *audio = (int16_t *)malloc((size_t)TOTAL * 2 * sizeof(int16_t));
    if (!audio) {
        fprintf(stderr, "Could not allocate render buffer.\n");
        return 1;
    }

    double chords[8][5] = {
        {110.00, 164.81, 220.00, 277.18, 329.63},
        {103.83, 155.56, 207.65, 261.63, 329.63},
        {116.54, 174.61, 233.08, 293.66, 349.23},
        {98.00, 146.83, 196.00, 246.94, 293.66},
        {110.00, 146.83, 220.00, 261.63, 349.23},
        {123.47, 185.00, 246.94, 311.13, 369.99},
        {103.83, 164.81, 207.65, 261.63, 311.13},
        {98.00, 164.81, 196.00, 261.63, 329.63}
    };
    double octave_mul[2] = {0.5, 1.0};
    double octave_amp[2] = {0.043, 0.058};
    double pad_phase[8][5][2];
    double air_phase[5];
    double pulse_phase = 0.0, motif_phase = 0.0;
    for (int i = 0; i < 5; i++) {
        air_phase[i] = (i * 1.271 + 0.3);
        for (int c = 0; c < 8; c++) {
            for (int j = 0; j < 2; j++) pad_phase[c][i][j] = (c * 0.51 + i * 0.83 + j * 1.47);
        }
    }

    for (int64_t n = 0; n < TOTAL; n++) {
        double t = (double)n / SR;
        double pos = (t / DURATION) * 8.0;
        int ci = ((int)floor(pos)) % 8;
        double f = smoothstep(pos - floor(pos));
        double wa = 0.5 + 0.5 * cos(PI * f);
        double wb = 0.5 - 0.5 * cos(PI * f);
        int cj = (ci + 1) % 8;
        double l = 0.0, r = 0.0;

        double breath = 0.78 + 0.08 * sin(2 * PI * t / 480.0) + 0.04 * sin(2 * PI * t / 337.5);
        for (int c = 0; c < 8; c++) {
            double weight = c == ci ? wa : (c == cj ? wb : 0.0);
            if (weight <= 0.000001) continue;
            for (int note = 0; note < 5; note++) {
                for (int oct = 0; oct < 2; oct++) {
                    double period = 450.0 - note * 30.0 - oct * 45.0;
                    double detune = 1.0 + 0.0013 * sin(2 * PI * t / period + note + c * 0.25);
                    double base = qfreq(chords[c][note] * octave_mul[oct]);
                    pad_phase[c][note][oct] += 2 * PI * (base * detune) / SR;
                    if (pad_phase[c][note][oct] > 2 * PI) pad_phase[c][note][oct] = fmod(pad_phase[c][note][oct], 2 * PI);
                    double ph = pad_phase[c][note][oct];
                    double tone = sin(ph) + 0.18 * sin(2.0 * ph + 0.4);
                    double pan = 0.42 * sin(2 * PI * t / (600.0 - note * 60.0 + oct * 100.0) + note * 0.7 + c * 0.13);
                    pan_stereo(tone * octave_amp[oct] * weight * breath, pan, &l, &r);
                }
            }
        }

        double air_bases[5] = {523.25, 659.25, 783.99, 880.00, 987.77};
        for (int i = 0; i < 5; i++) {
            double period = 450.0 - i * 50.0;
            air_phase[i] += 2 * PI * (qfreq(air_bases[i]) * (1.0 + 0.0007 * sin(2 * PI * t / period))) / SR;
            if (air_phase[i] > 2 * PI) air_phase[i] -= 2 * PI;
            double amp = 0.0060 * (0.65 + 0.35 * sin(2 * PI * t / (300.0 - i * 25.0) + i));
            double pan = -0.65 + i * 0.32 + 0.1 * sin(2 * PI * t / 300.0);
            pan_stereo(sin(air_phase[i]) * amp, pan, &l, &r);
        }

        double density = 0.5 + 0.5 * sin(2 * PI * t / DURATION - PI / 2);
        double pulse = 0.020 * pulse_env(t, 7.5 - 1.3 * density, 0.055, 0.02)
                     + 0.010 * pulse_env(t, 11.25 + 2.0 * density, 0.045, 0.37)
                     + 0.007 * pulse_env(t, 18.0, 0.035, 0.71) * density;
        pulse_phase += 2 * PI * (55.0 + 1.5 * sin(2 * PI * t / 360.0)) / SR;
        if (pulse_phase > 2 * PI) pulse_phase -= 2 * PI;
        double pulse_tone = sin(pulse_phase) + 0.15 * sin(2 * pulse_phase);
        pan_stereo(pulse_tone * pulse, 0.05 * sin(2 * PI * t / 180.0), &l, &r);

        double gate = motif_gate(t);
        if (gate > 0.0) {
            double notes[6] = {329.63, 293.66, 261.63, 329.63, 369.99, 293.66};
            int step = ((int)floor(t * 0.42)) % 6;
            double local = fmod(t * 0.42, 1.0);
            double env = pow(sin(PI * local), 2.0);
            motif_phase += 2 * PI * qfreq(notes[step]) / SR;
            if (motif_phase > 2 * PI) motif_phase -= 2 * PI;
            pan_stereo(sin(motif_phase) * env * gate * 0.018, 0.28 * sin(2 * PI * t / 225.0), &l, &r);
        }

        l = tanh(l * 1.18) * 0.72;
        r = tanh(r * 1.18) * 0.72;
        audio[n * 2] = (int16_t)(clampd(l, -1.0, 1.0) * 32767.0);
        audio[n * 2 + 1] = (int16_t)(clampd(r, -1.0, 1.0) * 32767.0);

        if (n > 0 && n % (SR * 300) == 0) {
            fprintf(stderr, "rendered %.0f min\n", t / 60.0);
        }
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

    int16_t sl = audio[0], sr = audio[1];
    int16_t el = audio[(TOTAL - 1) * 2], er = audio[(TOTAL - 1) * 2 + 1];
    double delta_l = fabs((double)sl - el) / 32767.0;
    double delta_r = fabs((double)sr - er) / 32767.0;
    fprintf(stderr, "wrote %s\n", out);
    fprintf(stderr, "endpoint delta %.8f\n", delta_l > delta_r ? delta_l : delta_r);
    free(audio);
    return 0;
}

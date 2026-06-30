# Lugna Audio Requirements

## Required bundle files

MVP:

- `focus_loop.wav`
- `relax_loop.wav`
- `sleep_loop.wav`

Place files in `Fordybelse/Resources/Audio/` and make sure they are included in the app target's Copy Bundle Resources phase.

## Focus sound character

The final focus loop should be:

- warm, airy synth ambient;
- long-form and non-fatiguing;
- gently evolving rather than static;
- rhythmically soft, with subtle motion over time;
- free of nature associations such as rain, forest, ocean, fire, birds, wind, or field recordings;
- allowed to contain rare, sparse note motifs;
- designed for focus listening, not meditation branding;
- loop-friendly and unobtrusive at low volume.

## Technical requirements

- Format: `.m4a`, AAC or ALAC.
- Recommended sample rate: 44.1 kHz or 48 kHz.
- Recommended loudness: conservative, non-fatiguing, around -18 to -16 LUFS integrated.
- Peak ceiling: at or below -1.0 dBTP.
- Duration: long enough that repetition is not obvious. 20 to 60 minutes is preferred for v1.
- Loop: seamless. The file start and end must align musically and must not contain encoder clicks, abrupt reverb cuts, silence, or transient discontinuities.
- Export with a short crossfade or render a composition whose tail naturally resolves into the beginning.
- Test on AirPods, iPhone speaker at low volume, and one external speaker.

## Current placeholder

The repository currently uses WAV files copied from the local source renders. For release, mastered `.m4a` files are still preferred for app size; update `FocusMode.audioFileExtension` when switching formats.

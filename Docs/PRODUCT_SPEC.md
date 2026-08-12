# Månen Product Spec

## MVP intent

Månen is a minimal iPhone focus app for iOS 17+. The first version performs one Core Job:

`I want to enter a stable focus state with almost no interaction, in order to continue demanding work without adding another distracting product to my desk.`

The MVP should feel like a quiet digital ambient object, not a media player. It starts and stops one long-form focus soundscape and keeps the visual surface calm while audio plays.

## Target experience

- One screen only.
- Title: Månen.
- Status text: idle or active.
- One large play/pause control.
- Minimal mode preparation for Focus / Relax / Sleep, with Focus active in MVP.
- Animated abstract geometric background.
- Light and dark appearance.
- No timers, playlists, settings, scrubbers, equalizers, waveforms, nature references, or wellness clichés.

## Product principles

- Subtract interaction before adding functionality.
- Keep the Aha Moment early: one tap should create a calmer work state.
- Do not overpromise: the app is a focus soundscape, not therapy, meditation, sleep coaching, or productivity automation.
- Avoid visual novelty that competes with work. Motion should be slow, atmospheric, and legible only at the edge of attention.

## Mode structure

The code includes `FocusMode` cases for `focus`, `relax`, and `sleep`. The MVP now ships with `focus_loop.wav`, `relax_loop.wav`, and `sleep_loop.wav`; all three modes reuse the same `AudioManager`, `AppModel`, and view composition.

## Success criteria for MVP

- The focus soundscape starts in one tap.
- The sound loops without audible pause or click.
- Playback continues in the background and on the lock screen.
- Lock screen / Control Center shows Månen, not the file name.
- The screen stays visually premium and quiet in light and dark mode.
- No extra controls appear in the first version.

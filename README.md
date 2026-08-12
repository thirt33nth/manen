# Månen

Månen is a native SwiftUI iPhone app for iOS 17+. It is a minimal soundscape MVP: one screen, mode-specific ambient loops, calm abstract motion, and background audio support.

## Project tree

```text
Fordybelse.xcodeproj/
Fordybelse/
  FordybelseApp.swift
  Info.plist
  Models/
    AppModel.swift
    FocusMode.swift
  Services/
    AudioManager.swift
  Views/
    AmbientBackdrop.swift
    HomeView.swift
    ModeSelector.swift
    PlayPauseButton.swift
    ProductivityPeriodsToggle.swift
  Resources/
    Audio/
      focus_loop.wav
      relax_loop.wav
      sleep_loop.wav
    Sounds/
      productivity_cue.wav
  Assets.xcassets/
    AccentColor.colorset/
    AppIcon.appiconset/
    AmbientArtwork.imageset/
fastlane/
  Appfile
  Fastfile
Docs/
  PRODUCT_SPEC.md
  AUDIO_REQUIREMENTS.md
```

## Run

1. Open `Fordybelse.xcodeproj` in Xcode.
2. Select an iPhone simulator or a physical iPhone.
3. Set a development team if Xcode asks for signing.
4. Build and run.

Minimum target: iOS 17.0. Device family: iPhone.

## Fastlane

Install the project-local Fastlane dependencies:

```bash
bundle install
```

Build Månen for the iOS Simulator:

```bash
bundle exec fastlane ios build_simulator
```

Clean Fastlane's derived data folder:

```bash
bundle exec fastlane ios clean
```

Prepare a release archive after signing is configured in Xcode:

```bash
bundle exec fastlane ios archive_release
```

Upload to TestFlight after App Store Connect credentials are configured in `fastlane/Appfile`:

```bash
bundle exec fastlane ios beta
```

Upload a release build and metadata to App Store Connect without submitting for review:

```bash
bundle exec fastlane ios app_store
```

## Background audio capability

`Info.plist` already includes:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

In Xcode, also open the target settings and enable:

`Signing & Capabilities` -> `+ Capability` -> `Background Modes` -> `Audio, AirPlay, and Picture in Picture`.

## Replace manually before release

- Replace `Fordybelse/Resources/Audio/focus_loop.wav`, `relax_loop.wav`, and `sleep_loop.wav` with final mastered loops, or switch `FocusMode.audioFileExtension` to `m4a` for release.
- Replace `Fordybelse/Resources/Sounds/productivity_cue.wav` with a final mastered productivity-period cue if desired.
- Replace the generated Now Playing artwork placeholder with a final brand artwork asset if desired.
- Add a real 1024x1024 App Icon image in `Assets.xcassets/AppIcon.appiconset`.

## File roles

- `FordybelseApp.swift`: app entry point and root state container setup.
- `AppModel.swift`: UI-facing state and playback actions.
- `FocusMode.swift`: future-ready mode model for Focus / Relax / Sleep.
- `AudioManager.swift`: AVAudioSession, seamless loop playback, Now Playing, and remote controls.
- `HomeView.swift`: single-screen composition.
- `PlayPauseButton.swift`: central ambient object control.
- `ModeSelector.swift`: quiet mode preparation for future expansion.
- `ProductivityPeriodsToggle.swift`: compact control for 25-minute Focus cues.
- `AmbientBackdrop.swift`: slow SwiftUI Canvas background animation.
- `fastlane/Fastfile`: repeatable build, clean, archive, and TestFlight lanes.
- `PRODUCT_SPEC.md`: product constraints and MVP success criteria.
- `AUDIO_REQUIREMENTS.md`: final audio asset requirements.

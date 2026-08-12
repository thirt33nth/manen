fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build_simulator

```sh
[bundle exec] fastlane ios build_simulator
```

Build Månen for the iOS Simulator

### ios clean

```sh
[bundle exec] fastlane ios clean
```

Clean local build artifacts

### ios prepare_distribution_signing

```sh
[bundle exec] fastlane ios prepare_distribution_signing
```

Prepare App Store distribution signing

### ios archive_release

```sh
[bundle exec] fastlane ios archive_release
```

Create a Release archive for distribution

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Upload a Release archive to TestFlight

### ios app_store

```sh
[bundle exec] fastlane ios app_store
```

Upload Månen to App Store Connect without submitting for review

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Upload localized App Store screenshots without uploading a new binary

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

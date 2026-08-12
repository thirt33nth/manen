# App Store Metadata Checklist

Before running `bundle exec fastlane ios app_store`, fill the missing App Store Connect and public listing data.

## Required account data

- Apple Developer Team ID
- App Store Connect Team ID
- Apple ID email or App Store Connect API key
- Existing App Store Connect app record for bundle id `app.manen.mvp`, or permission to create it

## Required listing data

- Support URL
- Privacy Policy URL
- App category
- Age rating answers
- App privacy answers
- iPhone screenshots for required App Store sizes

## Current release lane behavior

The `ios app_store` lane archives the app and uploads it to App Store Connect with:

- `submit_for_review: false`
- `automatic_release: false`

That means it uploads the build and metadata, but does not submit the app for Apple review automatically.

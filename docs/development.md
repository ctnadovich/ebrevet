# Development

## Prerequisites

- macOS with Xcode for iOS development.
- Flutter with its bundled Dart SDK.
- Android tooling for Android development.
- VS Code with Flutter and Dart extensions, if using VS Code.

At the time these notes were created, the local environment reported Flutter
3.41.9 and Dart 3.11.5. Check the active environment with:

```sh
flutter --version
dart --version
```

`pubspec.yaml` currently declares `sdk: '>=2.18.6 <3.0.0'`, which does not
describe the installed Dart 3 toolchain. Resolve that constraint deliberately
before relying on a fresh dependency resolution.

## Common checks

```sh
flutter pub get
flutter analyze
flutter test
```

Run platform builds appropriate to the change before release. Avoid committing
generated build output or local IDE state.

## Working with persistent models

Changes to `Event`, `ActivatedEvent`, settings enums, or their JSON conversion
can affect data already stored on rider devices. Review read compatibility,
write compatibility, and migration behavior before making such changes.

Do not add real regional secrets, custom secrets, credentials, or production
rider data to documentation or test fixtures.

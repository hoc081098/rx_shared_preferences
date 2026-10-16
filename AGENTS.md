# Repository Guidelines

## Project Structure & Module Organization

- `lib/rx_shared_preferences.dart` exports the public API. `lib/src/` contains interfaces, extensions, configuration, logging, and implementations; adapters live under `impl/legacy/` and `impl/async/`.
- `test/` contains adapter and stream suites, `fake_shared_prefs_store.dart`, and fixtures in `model/`.
- `example/` is a Flutter demo with Android, iOS, and web targets. Documentation images include `rx_prefs.png` and `example/example.gif`.
- `.github/workflows/` defines package checks and Android example builds.

## Build, Test, and Development Commands

Use Flutter 3.35.0 or newer with Dart `>=3.9.0 <4.0.0`. Run these commands from the repository root:

- `flutter pub get`: resolve package dependencies.
- `dart format lib test example --set-exit-if-changed`: format Dart files and report formatting changes, matching CI.
- `flutter analyze lib test example`: check analyzer and lint rules.
- `flutter test`: run package tests.
- `flutter test --coverage --coverage-path=lcov.info`: generate the coverage report used by CI.

Inside `example/`, run `flutter pub get`, then `flutter run` to launch the demo. `flutter build apk --no-shrink` builds the Android example as CI does; use Java 17 and an Android SDK.

## Coding Style & Naming Conventions

Use two-space indentation and `dart format`. Name files `snake_case.dart`, types `UpperCamelCase`, and members `lowerCamelCase`. Follow `analysis_options.yaml`, which extends `flutter_lints`: prefer single quotes, final locals, relative imports within the package, explicit return types, and `///` documentation for public APIs. Handle asynchronous calls according to the `unawaited_futures` rule.

## Testing Guidelines

Use `flutter_test`, descriptive `group`/`test` names, and files ending in `_test.dart`. Run a focused suite with `flutter test test/async_streams_test.dart`.

Cover new code paths across the relevant legacy, async, and cached adapters. Use existing fake or in-memory platform stores and stream matchers such as `emitsInOrder`. Verify initial emissions, updates, null/removal behavior, type errors, and reload notifications when affected. CI uploads coverage to Codecov; no numeric coverage threshold is configured here.

## Commit & Pull Request Guidelines

History mixes Conventional Commits and free-form messages. Use `<type>(<scope>): <summary>`, for example `fix(streams): emit null after removal`.

Keep PRs focused; describe behavior changes, validation performed, and relevant issues. Update `README.md`, `CHANGELOG.md`, and examples when public behavior changes. Discuss fundamental changes through a lightweight issue or example PR, as described in `CONTRIBUTING.md`.

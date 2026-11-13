# Repository Guidelines

## Project Structure & Module Organization

- `lib/rx_shared_preferences.dart` exports the public API. `lib/src/` contains interfaces, extensions, configuration, logging, and implementations; adapters live under `impl/legacy/` and `impl/async/`.
- `test/` contains adapter and stream suites, `fake_shared_prefs_store.dart`, and fixtures in `model/`.
- `example/` is a Flutter demo with Android, iOS, and web targets. Documentation images include `rx_prefs.png` and `example/example.gif`.
- `.github/workflows/` defines package checks and Android example builds.

## Build, Test, and Development Commands

Package-only commands require Flutter 3.35.0 or newer with Dart `>=3.9.0 <4.0.0`. The example and combined `lib test example` checks require Flutter `>=3.47.0` and Dart `>=3.13.0 <4.0.0`. Run these commands from the repository root:

- `flutter pub get --no-example`: resolve package dependencies separately from the example.
- `dart format --output=none --set-exit-if-changed lib test example`: check Dart formatting without modifying files, matching CI.
- `flutter analyze --no-pub lib test example`: check analyzer and lint rules.
- `flutter test --no-pub`: run package tests.
- `flutter test --no-pub --coverage --coverage-path=coverage/lcov.info`: generate the coverage report used by CI.
- `dart doc --validate-links`: generate API documentation and fail on broken links or unresolved references.
- `dart pub publish --dry-run`: validate package contents without publishing. Inspect the file list and resolve all warnings.

Inside `example/`, run `flutter pub get` before the combined formatting and analysis checks. Run `flutter test --no-pub` for example tests or `flutter run` to launch the demo. `flutter build apk --release --no-pub` builds the Android example as CI does; use Java 17 and an Android SDK.

## Coding Style & Naming Conventions

Use two-space indentation and `dart format`. Name files `snake_case.dart`, types `UpperCamelCase`, and members `lowerCamelCase`. Follow `analysis_options.yaml`, which extends `flutter_lints`: prefer single quotes, final locals, relative imports within the package, explicit return types, and `///` documentation for public APIs. Handle asynchronous calls according to the `unawaited_futures` rule.

In Dartdoc and documentation prose (including `.md` files), prefer short sentences and natural conjunctions. Use semicolons (`;`) and em dashes only when needed for clarity.

## Testing Guidelines

Use `flutter_test`, descriptive `group`/`test` names, and files ending in `_test.dart`. Run a focused suite with `flutter test --no-pub test/async_streams_test.dart`.

Cover new code paths across the relevant legacy, async, and cached adapters. Use existing fake or in-memory platform stores and stream matchers such as `emitsInOrder`. Verify initial emissions, updates, null/removal behavior, type errors, and reload notifications when affected. CI uploads coverage to Codecov; no numeric coverage threshold is configured here.

## Commit & Pull Request Guidelines

History mixes Conventional Commits and free-form messages. Use `<type>(<scope>): <summary>`, for example `fix(streams): emit null after removal`.

Keep PRs focused; describe behavior changes, validation performed, and relevant issues. Update `README.md`, `CHANGELOG.md`, and examples when public behavior changes. Discuss fundamental changes through a lightweight issue or example PR, as described in `CONTRIBUTING.md`.

## Agent skills

### Issue tracker

Issues and specs live in GitHub Issues. For issue operations, read `docs/agents/issue-tracker.md`.

### Triage labels

When triaging issues, use the role mapping in `docs/agents/triage-labels.md`.

### Domain docs

This repo uses a single context. Before exploring domain concepts or architecture decisions, read `docs/agents/domain.md`.

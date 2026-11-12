# RxSharedPreferences examples

Requires Flutter `>=3.47.0` and Dart `>=3.13.0 <4.0.0` for the example's
dependencies. The package itself still supports Flutter `>=3.35.0` and Dart
`>=3.9.0 <4.0.0`.

The ListView demo uses the standalone `material_ui` package. Android builds use
Java 17, AGP 9.3.1, and Gradle 9.5.0. Built-in Kotlin and the new AGP DSL remain
disabled while the locked Android plugins use the Kotlin Gradle Plugin.

Run commands from this directory:

```sh
flutter pub get
flutter run
```

- [ListView demo](lib/main.dart): render a list from preference streams.
- [API snippets](lib/snippet.dart): typed values, custom codecs and bulk streams.
- [Secure storage adapter](lib/flutter_secure_storage_snippet.dart): implement
  `SharedPreferencesLike` and use `RxSharedPreferences.custom` with
  `flutter_secure_storage`.

To run the secure storage snippet, follow the plugin's
[platform setup instructions](https://pub.dev/packages/flutter_secure_storage),
then run:

```sh
flutter run -t lib/flutter_secure_storage_snippet.dart
```

The snippet logs token presence, writes a sample string, removes it, and disposes
its subscription and reactive wrapper. It does not display a UI. It leaves
storage logging disabled because those events include stored values.

The adapter accepts encoded strings and treats encoded nulls as removals. Use
the string helpers, or generic `read`/`write`/`observe`/`update` methods with codecs
that convert values to and from strings. Direct changes through
`FlutterSecureStorage` need `rxPrefs.reload()` to notify string-valued key streams.
If a key stream uses a logical type such as `int`, pass a matching entry decoder:

```dart
await rxPrefs.reload(
  (key, raw) => key == 'encoded_count' && raw is String ? int.parse(raw) : raw,
);
```

The [API snippets](lib/snippet.dart) also show reload decoding for a custom `User`.

Run the adapter and reactive integration tests with the plugin's in-memory store:

```sh
flutter test
```

# rx_shared_preferences ![alt text](https://avatars3.githubusercontent.com/u/6407041?s=32&v=4)

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/0eada0cc95ce4adeb49ace73d5adf15d)](https://app.codacy.com/gh/hoc081098/rx_shared_preferences?utm_source=github.com&utm_medium=referral&utm_content=hoc081098/rx_shared_preferences&utm_campaign=Badge_Grade_Settings)
[![Pub](https://img.shields.io/pub/v/rx_shared_preferences.svg)](https://pub.dartlang.org/packages/rx_shared_preferences)
[![Pub](https://img.shields.io/pub/v/rx_shared_preferences.svg?include_prereleases)](https://pub.dartlang.org/packages/rx_shared_preferences)
[![codecov](https://codecov.io/gh/hoc081098/rx_shared_preferences/branch/master/graph/badge.svg)](https://codecov.io/gh/hoc081098/rx_shared_preferences)
[![Build example](https://github.com/hoc081098/rx_shared_preferences/actions/workflows/build-example.yml/badge.svg)](https://github.com/hoc081098/rx_shared_preferences/actions/workflows/build-example.yml)
[![Flutter CI](https://github.com/hoc081098/rx_shared_preferences/actions/workflows/tests.yml/badge.svg?branch=master)](https://github.com/hoc081098/rx_shared_preferences/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Style](https://img.shields.io/badge/style-lints-40c4ff.svg)](https://pub.dev/packages/lints)
[![Hits](https://hits.sh/github.com/hoc081098/rx_shared_preferences.svg)](https://hits.sh/github.com/hoc081098/rx_shared_preferences/)

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-1-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

-   Shared preferences with `rxdart` stream observation.
-   Reactive shared preferences for `Flutter`.
-   Reactive stream wrapper around SharedPreferences.
-   This package provides reactive shared preferences interaction with very little code. It is designed specifically to be used with Flutter and Dart.

## Buy me a coffee

Liked some of my work? Buy me a coffee (or more likely a beer)

<a href="https://www.buymeacoffee.com/hoc081098" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" height=64></a>

## Note

Since version `1.3.4`, this package is an extension of [rx_storage](https://github.com/Flutter-Dart-Open-Source/rx_storage) package.

## More details about the returned `Stream`

-   It's a **single-subscription `Stream`** (i.e. it can only be listened to once).

-   `Stream` will emit the **value (nullable)** or **a `TypeError`** as its first event when it is listened to.

-   It will **automatically** emit the new value when the value associated with key was changed successfully
    (it will also **emit `null`** when value associated with key was `removed` or set to `null`).

-   When value read from Storage has a type other than expected type:
    -   If value is `null`, the `Stream` will **emit `null`** (this occurred because `null` can be cast to any nullable type).
    -   Otherwise, the `Stream` will **emit a `TypeError`**.

-   **Can emit** two consecutive data events that are equal.
    You should use Rx operator like `distinct`
    (more commonly known as `distinctUntilChanged` in other Rx implementations)
    to create a `Stream` where data events are skipped if they are equal to the previous data event.

```text
Key changed   |----------K1---K2------K1----K1-----K2---------> time
              |                                                
Value stream  |-----@----@------------@-----@-----------------> time
              |    ^                                      
              |    |
              |  Listen(key=K1)
              |
              |  @: nullable value or TypeError
```
<p align="center">
    <img src="https://github.com/hoc081098/rx_shared_preferences/raw/master/rx_prefs.png" width="700">
</p>

## Getting Started

Requires Flutter `>=3.35.0` and Dart `>=3.9.0 <4.0.0`.
Upgrading from 4.x? See the [5.0.0 migration guide](https://github.com/hoc081098/rx_shared_preferences/blob/master/MIGRATION.md).

In your Flutter project, add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  [...]
  rx_shared_preferences: ^5.0.0
```

## Usage

### 1. Import and instantiate

-   Import `rx_shared_preferences`.

```dart
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
```

-   Choose a shared preferences API. For new code, use the async or cached API.

```dart
final rxPrefs = RxSharedPreferences.async(SharedPreferencesAsync());
final rxPrefs = RxSharedPreferences.getAsyncInstance(); // default async singleton

final rxPrefs = RxSharedPreferences.withCache(
  SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  ),
);
final rxPrefs = RxSharedPreferences.getWithCacheInstance(); // default cached singleton
```

`RxSharedPreferences.async` and `RxSharedPreferences.withCache` are experimental.
The legacy `SharedPreferences` API remains available:

```dart
// via constructor.
final rxPrefs = RxSharedPreferences(await SharedPreferences.getInstance()); // use await
final rxPrefs = RxSharedPreferences(SharedPreferences.getInstance());       // await is optional
final rxPrefs = RxSharedPreferences.getInstance();                          // default singleton instance

// via extension.
final rxPrefs = (await SharedPreferences.getInstance()).rx;                 // await is required
```

> NOTE: When using a default singleton or the extension `(await SharedPreferences.getInstance()).rx`,
> configure the logger with the `RxSharedPreferencesConfigs.logger` setter.

### 2. Add a logger (optional)

You can pass a logger as an optional argument to the `RxSharedPreferences` constructor.
The logger will log messages about operations (such as read, write, ...) and stream events.
This package provides two `RxSharedPreferencesLogger`s: 
-   `RxSharedPreferencesDefaultLogger`. 
-   `RxSharedPreferencesEmptyLogger`.

```dart
final rxPrefs = RxSharedPreferences(
  SharedPreferences.getInstance(),
  kReleaseMode ? null : RxSharedPreferencesDefaultLogger(),
  // disable logging when running in release mode.
);
```

> NOTE: To disable logging when running in release mode, you can pass `null` or `const RxSharedPreferencesEmptyLogger()` 
> to `RxSharedPreferences` constructor, or use `RxSharedPreferencesConfigs.logger` setter.

> NOTE: To prevent printing `↓ Disposed successfully → DisposeBag#...`, disable the `DisposeBag` logger:
> ```dart
> import 'package:disposebag/disposebag.dart' show DisposeBagConfigs;
> void main() {
>   DisposeBagConfigs.logger = null;
> }
> ```

### 3. Select stream and observe

-   Listen to the `Stream`s and transform them with operators such as `map` and `flatMap`.
-   If you need to listen to the `Stream` many times, you can use broadcast operators such as `share`, `shareValue`, `publish`, `publishValue`, etc...

```dart
// Listen
rxPrefs.getStringListStream('KEY_LIST').listen(print);                  // [*]

// Broadcast stream
rxPrefs.getStringListStream('KEY_LIST').share();
rxPrefs.getStringListStream('KEY_LIST').shareValue();
rxPrefs.getStringListStream('KEY_LIST').asBroadcastStream();

// Transform stream
rxPrefs.getIntStream('KEY_INT')
  .map((i) => /* Do something cool */)
  .where((i) => /* Filtering */)
  ...

// must **use same rxPrefs** instance when set value and select stream
await rxPrefs.setStringList('KEY_LIST', ['Cool']);                      // [*] will print ['Cool']
```

-   In the previous example, we re-used the `RxSharedPreferences` object `rxPrefs` for all operations.
    All operations must go through this object in order to correctly notify subscribers.
    Basically, you must use the same `RxSharedPreferences` instance when setting values and selecting streams.

-   In a Flutter app, you can:
    -   Create a global `RxSharedPreferences` instance.
        
    -   Use the default singleton instance via `RxSharedPreferences.getInstance()`.
        
    -   Use `InheritedWidget`/`Provider` to provide a `RxSharedPreferences` instance (create it in `main` function) for all widgets (recommended). 
        See [example/main](https://github.com/hoc081098/rx_shared_preferences/blob/95642a7fe8e8e0ad4579d7ae084aec9a10fe6dff/example/lib/main.dart#L17).

```dart
// An example for wrong usage.

rxPrefs1.getStringListStream('KEY_LIST').listen(print); // [*]

rxPrefs2.setStringList('KEY_LIST', ['Cool']);           // [*] will not print anything,
                                                        // because rxPrefs1 and rxPrefs2 are different instances.
```

### 4. Stream APIs and RxStorage APIs

-   All `Stream`s APIs (via extension methods).

```dart
  Stream<Object?>              getObjectStream(String key, [Decoder<Object?>? decoder]);
  Stream<bool?>                getBoolStream(String key);
  Stream<double?>              getDoubleStream(String key);
  Stream<int?>                 getIntStream(String key);
  Stream<String?>              getStringStream(String key);
  Stream<List<String>?>        getStringListStream(String key);
  Stream<Set<String>>          getKeysStream();

  Future<void>                 updateBool(String key, Transformer<bool?> transformer);
  Future<void>                 updateDouble(String key, Transformer<double?> transformer);
  Future<void>                 updateInt(String key, Transformer<int?> transformer);
  Future<void>                 updateString(String key, Transformer<String?> transformer);
  Future<void>                 updateStringList(String key, Transformer<List<String>?> transformer);
```

-   All methods from [RxStorage](https://pub.dev/documentation/rx_storage/latest/rx_storage/RxStorage-class.html) 
    (because `RxSharedPreferences` implements `RxStorage`).

```dart
  Future<void>                 update<T extends Object>({required String key, required Decoder<T?> decoder, required Transformer<T?> transformer, required Encoder<T?> encoder, void options});
  Stream<T?>                   observe<T extends Object>(String key, Decoder<T?> decoder);
  Stream<Map<String, Object?>> observeAll(EntryDecoder<String> decoder, [void options]);
  Future<void>                 dispose();
```

### 5. Get and set methods like `SharedPreferences`

-   Like `SharedPreferences`, `RxSharedPreferences` provides read and write methods (via extension methods).

```dart
  Future<Object?>              getObject(String key, [Decoder<Object?>? decoder]);
  Future<bool?>                getBool(String key);
  Future<double?>              getDouble(String key);
  Future<int?>                 getInt(String key);
  Future<Set<String>>          getKeys();
  Future<String?>              getString(String key);
  Future<List<String>?>        getStringList(String key);

  Future<Map<String, Object?>> reload();
  Future<void>                 setBool(String key, bool? value);
  Future<void>                 setDouble(String key, double? value);
  Future<void>                 setInt(String key, int? value);
  Future<void>                 setString(String key, String? value);
  Future<void>                 setStringList(String key, List<String>? value);
```

-   All methods from [Storage](https://pub.dev/documentation/rx_storage/latest/rx_storage/Storage-class.html)
   (because `RxSharedPreferences` implements `Storage`).

```dart
  Future<bool>                 containsKey(String key);
  Future<T?>                   read<T extends Object>(String key, Decoder<T?> decoder);
  Future<Map<String, Object?>> readAll(EntryDecoder<String> decoder, [void options]);
  Future<void>                 clear();
  Future<void>                 remove(String key);
  Future<void>                 write<T extends Object>(String key, T? value, Encoder<T?> encoder);
```

### 6. Read and observe all entries

Bulk reads require an `EntryDecoder<String>`. It receives each existing key and
its stored value, and may return a synchronous value or a `Future`. Values in
the resulting map can have different types. A decoded `null` retains its key;
removed keys are omitted.

```dart
final raw = await rxPrefs.readAll((_, raw) => raw);
final decoded = await rxPrefs.readAll((key, raw) {
  if (key == 'name' && raw is String) return raw.toUpperCase();
  return raw;
});

final changes = rxPrefs.observeAll((key, raw) async {
  if (key == 'name' && raw is String) return raw.toUpperCase();
  return raw;
});
```

Each bundled adapter captures a shallow entry snapshot before decoding. Entry
decoders may run concurrently. Reading or decoding failures fail the bulk read
without returning a partial map. Decoders do not roll back their side effects.

`observeAll` emits an initial decoded map, then reads and decodes again after
successful writes, updates, removals, clears, and reloads through the same
wrapper. Reads and async decoding complete in stream order; a read can reflect
later mutations rather than the exact state when it was triggered. Read or
decoding failures become stream errors; later changes can still be observed.
The stream is single-subscription.

`reload()` returns raw values and notifies observers of external additions,
updates, and removals. Removed keys emit `null` on their key streams. This also
works with the async adapter for keys previously read or written through the
wrapper. External changes are observed when you call `reload()`.

### 7. Dispose

You can dispose the `RxSharedPreferences` when it is no longer needed.
Just call `rxPrefs.dispose()`.
Usually, you call this method from the `dispose` method of a Flutter `State`.

Await required writes before disposal. Queued mutations and reloads that have
not started fail with `StateError`; started operations may finish without
further notifications or log events. Repeated disposal shares the same result
and invokes the cleanup callback at most once. Disposal preserves stored data.

### 8. Custom implementations and loggers

Implement `SharedPreferencesLike`, `RxSharedPreferences`, or
`RxSharedPreferencesLogger` to provide custom implementations. These contracts
are `abstract interface` classes and cannot be extended outside their library.
Custom adapters must implement entry decoding in `readAll`.

To reuse the built-in logger, extend it with a `base`, `final`, or `sealed`
subclass and override `handleLogEvent`. For example:

```dart
final class AppLogger extends RxSharedPreferencesDefaultLogger {
  const AppLogger() : super(tag: 'App preferences');
}
```

`ReloadSuccessEvent` and `ReloadFailureEvent` are final. Define additional custom
events by implementing `RxStorageLoggerEvent<String, void>`.

## Example demo

| [Simple authentication app with `BLoC rxdart pattern`](https://github.com/hoc081098/node-auth-flutter-BLoC-pattern-RxDart.git)               | [Build ListView from Stream using `RxSharedPreferences`](https://github.com/hoc081098/rx_shared_preferences/tree/master/example) | [Change theme and locale (language) runtime](https://github.com/hoc081098/bloc_rxdart_playground/tree/master/flutter_change_theme)    |
|----------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| <img src="https://github.com/hoc081098/node-auth-flutter-BLoC-pattern-RxDart/blob/master/screenshots/Screenshot3.png?raw=true" height="480"> | <img src="https://github.com/hoc081098/rx_shared_preferences/blob/master/example/example.gif?raw=true" height="480">             | <img src="https://github.com/hoc081098/bloc_rxdart_playground/blob/master/flutter_change_theme/Screenshot.gif?raw=true" height="480"> |

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/hoc081098/rx_shared_preferences/issues

## License

```text
MIT License

Copyright (c) 2019-2026 Petrus Nguyễn Thái Học
```

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://www.linkedin.com/in/hoc081098/"><img src="https://avatars.githubusercontent.com/u/36917223?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Petrus Nguyễn Thái Học</b></sub></a><br /><a href="https://github.com/hoc081098/rx_shared_preferences/commits?author=hoc081098" title="Code">💻</a> <a href="https://github.com/hoc081098/rx_shared_preferences/commits?author=hoc081098" title="Documentation">📖</a> <a href="#maintenance-hoc081098" title="Maintenance">🚧</a></td>
  </tr>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!

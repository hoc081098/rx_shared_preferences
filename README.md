# rx_shared_preferences ![alt text](https://avatars3.githubusercontent.com/u/6407041?s=32&v=4)

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/0eada0cc95ce4adeb49ace73d5adf15d)](https://app.codacy.com/gh/hoc081098/rx_shared_preferences?utm_source=github.com&utm_medium=referral&utm_content=hoc081098/rx_shared_preferences&utm_campaign=Badge_Grade_Settings)
[![Pub](https://img.shields.io/pub/v/rx_shared_preferences.svg)](https://pub.dartlang.org/packages/rx_shared_preferences)
[![Pub](https://img.shields.io/pub/v/rx_shared_preferences.svg?include_prereleases)](https://pub.dartlang.org/packages/rx_shared_preferences)
[![codecov](https://codecov.io/gh/hoc081098/rx_shared_preferences/branch/master/graph/badge.svg)](https://codecov.io/gh/hoc081098/rx_shared_preferences)
[![Build Status](https://travis-ci.com/hoc081098/rx_shared_preferences.svg?branch=master)](https://travis-ci.com/hoc081098/rx_shared_preferences)
[![Build example](https://github.com/hoc081098/rx_shared_preferences/actions/workflows/build-example.yml/badge.svg)](https://github.com/hoc081098/rx_shared_preferences/actions/workflows/build-example.yml)
![Flutter CI](https://github.com/hoc081098/rx_shared_preferences/workflows/Flutter%20CI/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Style](https://img.shields.io/badge/style-lints-40c4ff.svg)](https://pub.dev/packages/lints)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fhoc081098%2Frx_shared_preferences&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-1-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

-   Shared preference with `rxdart` Stream observation.
-   Reactive shared preferences for `Flutter`.
-   Reactive stream wrapper around SharedPreferences.
-   This package provides reactive shared preferences interaction with very little code. It is designed specifically to be used with Flutter and Dart.

## Buy me a coffee

Liked some of my work? Buy me a coffee (or more likely a beer)

<a href="https://www.buymeacoffee.com/hoc081098" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" height=64></a>

## Note

Since version `1.3.4`, this package is an extension of [rx_storage](https://github.com/Flutter-Dart-Open-Source/rx_storage) package.

## More details about the returned `Stream`

-   It's a **single-subscription `Stream`** (i.e. it can only be listened once).

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

In your flutter project, add the dependency to your `pubspec.yaml`

```yaml
dependencies:
  [...]
  rx_shared_preferences: <latest_version>
```

## Usage

### 1. Import and instantiate

-   Import `rx_shared_preferences`.

```dart
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
```

-   Wrap your `SharedPreferences` in a `RxSharedPreferences`.

```dart
// via constructor.
final rxPrefs = RxSharedPreferences(await SharedPreferences.getInstance()); // use await
final rxPrefs = RxSharedPreferences(SharedPreferences.getInstance());       // await is optional
final rxPrefs = RxSharedPreferences.getInstance();                          // default singleton instance

// via extension.
final rxPrefs = (await SharedPreferences.getInstance()).rx;                 // await is required
```

> NOTE: When using `RxSharedPreferences.getInstance()` and extension `(await SharedPreferences.getInstance()).rx`, 
> to config the logger, you can use `RxSharedPreferencesConfigs.logger` setter.

### 2. Add a logger (optional)

You can pass a logger to the optional parameter of `RxSharedPreferences` constructor.
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

> NOTE: To prevent printing `↓ Disposed successfully → DisposeBag#...`.
> ```dart
> import 'package:disposebag/disposebag.dart' show DisposeBagConfigs;
> void main() {
>   DisposeBagConfigs.logger = null;
> }
> ```

### 3. Select stream and observe

-   Then, just listen `Stream`s, transform `Stream`s through operators such as `map`, `flatMap`, etc...
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
    Basically, you must use the same `RxSharedPreferences` instance when set value and select stream.

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
  Future<void>                 update<T extends Object>(String key, Decoder<T?> decoder, Transformer<T?> transformer, Encoder<T?> encoder);
  Stream<T?>                   observe<T extends Object>(String key, Decoder<T?> decoder);
  Stream<Map<String, Object?>> observeAll();
  Future<void>                 dispose();
```

### 5. Get and set methods likes `SharedPreferences`

-   `RxSharedPreferences` is like to `SharedPreferences`, it provides `read`, `write` functions (via extension methods).

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
  Future<Map<String, Object?>> readAll();
  Future<void>                 clear();
  Future<void>                 remove(String key);
  Future<void>                 write<T extends Object>(String key, T? value, Encoder<T?> encoder);
```

### 5. Dispose

You can dispose `RxSharedPreferences` when is no longer needed.
Just call `rxPrefs.dispose()`.
Usually you call this method on `dispose` of a `State`

> NOTE: If you use the default singleton instance (via `RxSharedPreferences.getInstance()`,
> you should **not** call `dispose` method,
> must keep the instance alive for the entire lifetime of the application.


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

Copyright (c) 2019-2023 Petrus Nguyễn Thái Học
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

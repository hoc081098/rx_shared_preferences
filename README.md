# rx_shared_preferences ![alt text](https://avatars3.githubusercontent.com/u/6407041?s=32&v=4)

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/394a0db269db40bda248dd63ec84a292)](https://app.codacy.com/app/hoc081098/rx_shared_preferences?utm_source=github.com&utm_medium=referral&utm_content=hoc081098/rx_shared_preferences&utm_campaign=Badge_Grade_Dashboard)
[![Pub](https://img.shields.io/pub/v/rx_shared_preferences.svg)](https://pub.dartlang.org/packages/rx_shared_preferences)
[![codecov](https://codecov.io/gh/hoc081098/rx_shared_preferences/branch/master/graph/badge.svg)](https://codecov.io/gh/hoc081098/rx_shared_preferences)
[![Build Status](https://travis-ci.org/hoc081098/rx_shared_preferences.svg?branch=master)](https://travis-ci.org/hoc081098/rx_shared_preferences)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

-   Shared preference with `rxdart` Stream observation.
-   Reactive shared preferences for `Flutter`.
-   Reactive stream wrapper around SharedPreferences.
-   This package provides reactive shared preferences interaction with very little code. It is designed specifically to be used with Flutter and Dart.

## More detail about returned `Stream`
-   It's a single-subscription stream (ie. it can only be listened once).

-   `Stream` will emit the **value** or **error** as its first event when it is listen to (**emit `null`** when value is not set).

-   It will automatic emits value when value associated with key was changed successfully (**emit `null`** when value associated with key was `removed` or set to `null`).

-   When read value is invalid type (ie. wrong type):
    -   If value is present (ie. not `null`), the stream will **emit `TypeError` error** .
    -   Otherwise, the stream will **emit `null`** (this occurred because `null` can be cast to any type).

-   **Can emit** two consecutive data events that are equal. You should use Rx operator like `distinct` (More commonly known as `distinctUntilChanged` in other Rx implementations) to create an `Stream` where data events are skipped if they are equal to the previous data event.

<p align="center">
    <img src="https://github.com/hoc081098/rx_shared_preferences/raw/master/rx_prefs.png" width="700">
</p>

## Getting Started

In your flutter project, add the dependency to your `pubspec.yaml`

```yaml
dependencies:
  ...
  rx_shared_preferences: ^1.3.0
```

## Usage

### 1. Import and instance

Import `rx_shared_preferences` and `shared_preferences`

```dart
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

Wrap your `SharedPreferences` in a `RxSharedPreferences`.

```dart
final rxPrefs = RxSharedPreferences(await SharedPreferences.getInstance());
final rxPrefs = RxSharedPreferences(SharedPreferences.getInstance()); // await is optional
final rxPrefs = RxSharedPreferences.getInstance(); // default singleton instance
```

### 2. Can add a logger

You can add logger optional parameter to `RxSharedPreferences` constructor.
Logger will log messages about operations (such as read, write) and stream events

```dart
final rxPrefs = RxSharedPreferences(
  SharedPreferences.getInstance(),
  const DefaultLogger(),
);
```

You can custom `Logger` by implements `Logger`, or extends class `LoggerAdapter` (with empty implementations)
```dart
class MyLogger extends LoggerAdapter {
  const MyLogger();

  @override
  void readValue(Type type, String key, value) {
    // do something
  }
}

final rxPrefs = RxSharedPreferences(
  SharedPreferences.getInstance(),
  const MyLogger(),
);
```

### 3. Select stream and use

-   And then, just listen `Stream`, transform `Stream` through operators such as (`map`, `flatMap`, etc...).
-   If you need listen to this `Stream` many times, you can use broadcast operators such as `share`, `shareValue`, `publish`, `publishValue`, etc...

```dart
// Listen
rxPrefs.getStringListStream('KEY_LIST').listen(print); // [*]

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
rxPrefs.setStringList('KEY_LIST', ['Cool']); // [*] will print ['Cool']

```

-   In the previous example we re-used the RxSharedPreferences object `rxPrefs` for set operations. All set operations must go through this object in order to correctly notify subscribers.

-   In flutter, you:
    -   Can create global `RxSharedPreferences` instance.
    -   Using singleton instance `RxSharedPreferences.getInstance()`
    -   Can use `InheritedWidget`/`Provider` to provide a `RxSharedPreferences` instance (create it in `main` function) for all widgets (recommended). See [example/main](https://github.com/hoc081098/rx_shared_preferences/blob/1f33fd817ce7d6d686e1271a5d420cce67efd7aa/example/lib/main.dart#L10), [example/provider](https://github.com/hoc081098/rx_shared_preferences/blob/1f33fd817ce7d6d686e1271a5d420cce67efd7aa/example/lib/rx_prefs_provider.dart#L5).

```dart
rxPrefs1.getStringListStream('KEY_LIST').listen(print); // [*]

rxPrefs2.setStringList('KEY_LIST', ['Cool']); // [*] will not print anything
```

The previous example is wrong usage.

### 4. Get and set methods like to `SharedPreferences`
`RxSharedPreferences` is like to `SharedPreferences`, it provides read, write functions:

```dart
-   Future<bool> containsKey(String key);
-   Future<dynamic> get(String key);
-   Future<bool> getBool(String key);
-   Future<double> getDouble(String key);
-   Future<int> getInt(String key);
-   Future<Set<String>> getKeys();
-   Future<String> getString(String key);
-   Future<List<String>> getStringList(String key);

-   Future<bool> clear();
-   Future<void> reload();
-   Future<bool> commit();
-   Future<bool> remove(String key);
-   Future<bool> setBool(String key, bool value);
-   Future<bool> setDouble(String key, double value);
-   Future<bool> setInt(String key, int value);
-   Future<bool> setString(String key, String value);
-   Future<bool> setStringList(String key, List<String> value);
```

### 5. Dispose `RxSharedPreferences`

You can dispose `RxSharedPreferences` when is no longer needed. Just call `rxPrefs.dispose()`. Usually you call this method on `dispose` of a `State`

## Example demo

| [Simple authentication app with `BLoC rxdart pattern`](https://github.com/hoc081098/node-auth-flutter-BLoC-pattern-RxDart.git)          | [Build ListView from Stream using `RxSharedPreferences`](https://github.com/hoc081098/rx_shared_preferences/tree/master/example)          |  [Change theme and locale (language) runtime](https://github.com/hoc081098/bloc_rxdart_playground/tree/master/flutter_change_theme) |
| ------------- | ------------- | ------- |
| <img src="https://github.com/hoc081098/node-auth-flutter-BLoC-pattern-RxDart/blob/master/screenshots/Screenshot3.png?raw=true" height="480"> | <img src="https://github.com/hoc081098/rx_shared_preferences/blob/master/example/example.gif?raw=true" height="480"> |<img src="https://github.com/hoc081098/bloc_rxdart_playground/blob/master/flutter_change_theme/Screenshot.gif?raw=true" height="480"> |

## License
    Copyright (c) 2019 Petrus Nguyễn Thái Học

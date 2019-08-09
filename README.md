# rx_shared_preferences ![alt text](https://avatars3.githubusercontent.com/u/6407041?s=32&v=4)

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/394a0db269db40bda248dd63ec84a292)](https://app.codacy.com/app/hoc081098/rx_shared_preferences?utm_source=github.com&utm_medium=referral&utm_content=hoc081098/rx_shared_preferences&utm_campaign=Badge_Grade_Dashboard)
[![Pub](https://img.shields.io/pub/v/rx_shared_preferences.svg)](https://pub.dartlang.org/packages/rx_shared_preferences)
[![Build Status](https://travis-ci.org/hoc081098/rx_shared_preference.svg?branch=master)](https://travis-ci.org/hoc081098/rx_shared_preference)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

- Shared preference with RxDart Stream observation.
- Reactive shared preferences for Flutter.
- Reactive stream wrapper around SharedPreferences.
- This package provides reactive shared preferences interaction with very little code. It is designed specifically to be used with Flutter and Dart.

# More detail about returned `Observable`
- `Observable` will emit the **initial value** as its first next event (Emit value as soon as possible after is listen to) (**emit `null`** when value is not set) 
- It will automatic emit value when value associated with key was changed successfully (**emit `null`** when value associated with key was `removed` or set to `null`)
- When read value is not valid type (wrong type):
  + Will **emit error** if value is present (not `null`)
  + **Emit `null`** when value is absent (value is `null`) (this occurred because `null` can be cast to any type).
- Can emit **two consecutive data events that are equal**. You should use Rx operator like `distinct` (More commonly known as `distinctUntilChanged` in other Rx implementations) to create an `Observable` where data events are skipped if they are equal to the previous data event.

<img src="https://imgbbb.com/images/2019/08/09/carbon.png" width="600">

# Getting Started

In your flutter project, add the dependency to your `pubspec.yaml`

```yaml
dependencies:
  ...
  rx_shared_preferences: <latest_version>
```

# Usage

## 1. Import and instance

Import `rx_shared_preferences` and `shared_preferences`

```dart
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

Wrap your `SharedPreferences` in a `RxSharedPreferences`.

```dart
final rxPrefs = RxSharedPreferences(
  await SharedPreferences.getInstance()
);
```

or not need keyword `await` before `SharedPreferences.getInstance()`

```dart
final rxPrefs = RxSharedPreferences(
  SharedPreferences.getInstance()
);
```

## 2. Can add a logger

You can add logger optional parameter to `RxSharedPreferences` constructor.
Logger will log messages about operations (such as read, write) and observable values

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

## 3. Select observable (stream) and use

- And then, just listen `Observable`, transform `Observable` through operators such as (`map`, `flatMap`, etc...).
- If you need listen to this `Observable` many times, you can use broadcast operators such as `share`, `shareValue`, `publish`, `publishValue`, ...

- Note: RxDart's `Observables` extends the `Stream` class:

  * All methods defined on the Stream class exist on RxDart's Observables as well.
  * All Observables can be passed to any API that expects a Dart Stream as an input.
  * Additional important distinctions are documented as part of the Observable class

```dart
// Listen
rxPrefs.getStringListObservable('KEY_LIST').listen(print); // [*]

// Broadcast stream
rxPrefs.getStringListObservable('KEY_LIST').share();
rxPrefs.getStringListObservable('KEY_LIST').shareValue();

// Transform stream
rxPrefs.getIntObservable('KEY_INT')
  .map((i) => /* Do something cool */)
  .where((i) => /* Filtering */)
  ...

// must **use same rxPrefs** instance when set value and select stream
rxPrefs.setStringList('KEY_LIST', ['Cool']); // [*] will print ['Cool']

```
- In the previous example we re-used the RxSharedPreferences object `rxPrefs` for set operations. All set operations must go through this object in order to correctly notify subscribers.

- In flutter, you:
  + Can create global `RxSharedPreferences` instance.
  + Can use `InheritedWidget`/`Provider` to provide a `RxSharedPreferences` instance (create it in `main` function) for all widgets (recommended). See [example/main](https://github.com/hoc081098/rx_shared_preferences/blob/1f33fd817ce7d6d686e1271a5d420cce67efd7aa/example/lib/main.dart#L10), [example/provider](https://github.com/hoc081098/rx_shared_preferences/blob/1f33fd817ce7d6d686e1271a5d420cce67efd7aa/example/lib/rx_prefs_provider.dart#L5).

```dart
rxPrefs1.getStringListObservable('KEY_LIST').listen(print); // [*]

rxPrefs2.setStringList('KEY_LIST', ['Cool']); // [*] will not print anything
```
The previous example is wrong using way.

## 4. Get and set methods like to `SharedPreferences`
`RxSharedPreferences` is like to `SharedPreferences`, it provides read, write functions:

```dart
-  Future<bool> containsKey(String key);
-  Future<dynamic> get(String key);
-  Future<bool> getBool(String key);
-  Future<double> getDouble(String key);
-  Future<int> getInt(String key);
-  Future<Set<String>> getKeys();
-  Future<String> getString(String key);
-  Future<List<String>> getStringList(String key);

-  Future<bool> clear();
-  Future<void> reload();
-  Future<bool> commit();
-  Future<bool> remove(String key);
-  Future<bool> setBool(String key, bool value);
-  Future<bool> setDouble(String key, double value);
-  Future<bool> setInt(String key, int value);
-  Future<bool> setString(String key, String value);
-  Future<bool> setStringList(String key, List<String> value);
```

## 5. Dispose `RxSharedPreferences`

You can dispose `RxSharedPreferences` when is no longer needed. Just call `rxPrefs.dispose()`. Usually you call this method on `dispose` of a `State`

# Example demo:

## 1. [Build ListView from Stream using RxSharedPreferences](https://github.com/hoc081098/rx_shared_preferences/tree/master/example)

| Demo          | Code |
| ------------- | ------------- |
| <img src="https://github.com/hoc081098/rx_shared_preferences/blob/rename_package/example/example.gif?raw=true" width="240">  | <img src="https://imgbbb.com/images/2019/08/09/carbon-1.png" width="600">  |
  
</p>  

## 2. [Change theme and locale (language) runtime](https://github.com/hoc081098/bloc_rxdart_playground/tree/master/flutter_change_theme)

<p align="center">
<img src="https://github.com/hoc081098/bloc_rxdart_playground/blob/master/flutter_change_theme/Screenshot.gif?raw=true" width="240">
</p>

# License

    MIT License

    Copyright (c) 2019 Petrus Nguyễn Thái Học

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

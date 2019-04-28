# rx_shared_preference <img src="https://avatars3.githubusercontent.com/u/6407041?s=200&v=4" width="32">

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/394a0db269db40bda248dd63ec84a292)](https://app.codacy.com/app/hoc081098/rx_shared_preference?utm_source=github.com&utm_medium=referral&utm_content=hoc081098/rx_shared_preference&utm_campaign=Badge_Grade_Dashboard)
[![Pub](https://img.shields.io/pub/v/rx_shared_preference.svg)](https://pub.dartlang.org/packages/rx_shared_preference)
[![Build Status](https://travis-ci.org/hoc081098/rx_shared_preference.svg?branch=master)](https://travis-ci.org/hoc081098/rx_shared_preference)

Shared preference with RxDart Stream observation. Reactive shared preferences for Flutter. Reactive stream wrapper around SharedPreferences.

## Getting Started

In your flutter project, add the dependency to your `pubspec.yaml`

```yaml
dependencies:
  ...
  rx_shared_preference: ^1.0.0
```

## Usage

Import `rx_shared_preference` and `shared_preferences`

```dart
import 'package:rx_shared_preference/rx_shared_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

Wrap your `SharedPreferences` in a `RxSharedPreferences`.

```dart
final rxSharedPreferences = RxSharedPreferences(
  await SharedPreferences.getInstance()
);
```

or not need keyword `await` before `SharedPreferences.getInstance()`

```dart
final rxSharedPreferences = RxSharedPreferences(
  SharedPreferences.getInstance()
);
```

You can add logger optional parameter to `RxSharedPreferences` constructor.
Logger will log messages about operations (such as read, write) and observable values

```dart
final rxSharedPreferences = RxSharedPreferences(
  SharedPreferences.getInstance(),
  (message) => print('[RX_SHARED_PREF] :: $message'),
);
```

or simply pass `print` function to `RxSharedPreferences` constructor

```dart
final rxSharedPreferences = RxSharedPreferences(
  SharedPreferences.getInstance(),
  print,
);
```

And then, just listen `Observable`, transform `Observable` through operators such as (`map`, `flatMap`, etc...).
If you need listen to this `Observable` many times, you can use broadcast operators such as `share`, `shareValue`, `publish`, `publishValue`, ...

```dart
rxSharedPreferences.getStringListObservable('KEY').listen(print);

rxSharedPreferences.getStringListObservable('KEY').share();
rxSharedPreferences.getStringListObservable('KEY').shareValue();

rxSharedPreferences.getIntObservable('KEY')
  .map((i) => /*Do something cool*/)
  ...
  ...
```

`RxSharedPreferences` is like to `SharedPreferences`, it provides read write functions: `getBool`, `getDouble`,  `getInt`, ..., `setBool`, `setDouble`, `setInt`, etc...

License
-------

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

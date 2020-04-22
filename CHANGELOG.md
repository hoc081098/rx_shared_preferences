## 1.2.0 - Apr 20, 2020

*   Breaking change: support for `rxdart` 0.24.x.
*   Now, returned stream is broadcast stream.
*   Reset default singleton instance after disposing it.
*   Internal implementation refactor.

## 1.1.1+1 - Jan 29, 2020

*   Update `description` in `pubspec.yaml`.

## 1.1.1 - Jan 29, 2020

*   Add `getKeysStream` method to `IRxSharedPreferences`.
*   Add constructor `RxSharedPreferences.getInstance()` that returns default singleton `RxSharedPreferences` instance.
*   Internal implementation refactor & fix default logger.

## 1.1.0 - Dec 18, 2019

*   Update dependencies.
*   Now `IRxSharedPreferences`'s methods return `Stream` instead of `Observable`.

## 1.0.3+2 - Oct 7, 2019

*   Update dependencies.

## 1.0.3+1 - Aug 9, 2019

*   Update README.md.

## 1.0.3 - Aug 9, 2019

*   Publish new name package (previous name is [rx_shared_preference](https://pub.dev/packages/rx_shared_preference)).

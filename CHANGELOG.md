## 2.0.0-nullsafety.0 - Feb 24, 2021

*   **Breaking**
    -   Opt into _nullsafety_.
    -   Set Dart SDK constraints to `>=2.12.0-0 <3.0.0`.
    -   Using [shared_preferences: ^2.0.0](https://pub.dev/packages/shared_preferences/versions/2.0.0).
    -   Refactor `Logger` and implementation based on [rx_storage: ^1.0.0-nullsafety.0](https://pub.dev/packages/rx_storage/versions/1.0.0-nullsafety.0) package.

## 1.3.5 - Jan 4, 2021

*   Refactor based on [rx_storage: ^0.0.2](https://pub.dev/packages/rx_storage/versions/0.0.2) package.
*   The public API stays the same.

## 1.3.4 - Dec 18, 2020

*   Now, the internal implementation based on [rx_storage](https://pub.dev/packages/rx_storage/versions/0.0.1) package.
*   The public API stays the same.

## 1.3.3 - Oct 10, 2020

*   Fix: missing export `RxSharedPreferencesConfigs`.

## 1.3.2 - Oct 10, 2020

*   Add extension: `RxSharedPreferences get rx` for `SharedPreferences`.
    This allows writing concise code like this: `sharedPreferences.rx.getStringStream('key')`.

*   Allows changing logger for default singleton instance or extension: `RxSharedPreferencesConfigs.logger = ...`;

*   Internal implementation refactor.

## 1.3.1 - May 29, 2020

*   Update docs.

## 1.3.0 - May 28, 2020

*   **Breaking change**: returned stream is a **single-subscription** stream.
*   Internal implementation refactor.

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

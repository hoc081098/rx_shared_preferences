# Migrating from 4.x to 5.0.0

Requires Flutter `>=3.35.0`, Dart `>=3.9.0 <4.0.0`, and `rx_storage ^4.0.0`.
Run `flutter pub get` after upgrading. If you use `rxdart_ext` directly, upgrade
it to `^0.4.0` too.

## Bulk reads and streams require a decoder

Pass an identity decoder to keep raw values:

```dart
final raw = await rxPrefs.readAll((_, raw) => raw);
final changes = rxPrefs.observeAll((_, raw) => raw);
```

An `EntryDecoder<String>` receives `(key, raw)` and supports sync/async results.
Decoded nulls retain their keys; removed keys are omitted.
Custom adapters must accept this decoder in `readAll`; custom reactive
implementations must also update `observeAll`.

## Replace removed update methods

Replace `executeUpdateBool/Double/Int/String/StringList` with the matching
`update*` helper. The generic `executeUpdate` becomes `update` with named arguments:

```dart
await rxPrefs.updateInt('count', (current) async => (current ?? 0) + 1);

await rxPrefs.update<int>(
  key: 'count',
  decoder: (raw) => raw as int?,
  transformer: (current) async => (current ?? 0) + 1,
  encoder: (value) => value,
);
```

Updates remain experimental.

## Update custom class declarations

- Implement `SharedPreferencesLike`, `RxSharedPreferences`, and
  `RxSharedPreferencesLogger`; these are now `abstract interface` classes.
- Extend `RxSharedPreferencesDefaultLogger` with a `base`, `final`, or `sealed`
  subclass, or implement the logger contract for custom logging.
- `RxSharedPreferencesEmptyLogger`, `ReloadSuccessEvent`, and
  `ReloadFailureEvent` are final and cannot be extended or implemented.
- Re-exported `rx_storage` types also enforce Dart 3 class modifiers.

## Reload and disposal

Call `reload()` to observe external changes, including async key removals.
Removed keys emit `null` on key streams.

Await required writes before disposal. Queued mutations and reloads fail with
`StateError`; operations already running may finish without further notifications.
Legacy factories and `.rx` remain available.

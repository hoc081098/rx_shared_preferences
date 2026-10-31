# Migrating from 4.x to 5.0.0

Version 5.0.0 requires Flutter `>=3.35.0` and Dart `>=3.9.0 <4.0.0`,
and uses `rx_storage ^4.0.0`.
Set `rx_shared_preferences: ^5.0.0` in `pubspec.yaml`, then run `flutter pub get`.
If you depend directly on `rxdart_ext`, update it to `^0.4.0` too.

## Bulk reads and streams require a decoder

Pass an identity decoder to keep raw values:

```dart
final raw = await rxPrefs.readAll((_, raw) => raw);
final changes = rxPrefs.observeAll((_, raw) => raw);
```

An `EntryDecoder<String>` receives `(key, raw)` and can return a value or a `Future`.
Returning `null` keeps the key in the map; removed keys are omitted.
Custom adapters must implement entry decoding in `readAll`; custom reactive
implementations must also support it in `observeAll`.

## Replace removed update methods

Replace typed `executeUpdate*` helpers with their `update*` equivalents.
Replace the generic `executeUpdate` with `update` using named arguments:

```dart
await rxPrefs.updateInt('count', (current) => (current ?? 0) + 1);

await rxPrefs.update<int>(
  key: 'count',
  decoder: (raw) => raw as int?,
  transformer: (current) => (current ?? 0) + 1,
  encoder: (value) => value,
);
```

Transformers can return a value or a `Future`. Updates remain experimental.

## Update custom class declarations

- Use `implements` for `SharedPreferencesLike`, `RxSharedPreferences`, and
  `RxSharedPreferencesLogger`; each is now an `abstract interface class`.
- Extend `RxSharedPreferencesDefaultLogger` with a `base`, `final`, or `sealed`
  subclass, or implement `RxSharedPreferencesLogger` for custom logging.
- `RxSharedPreferencesEmptyLogger`, `ReloadSuccessEvent`, and
  `ReloadFailureEvent` are final and cannot be extended or implemented.
- Re-exported `rx_storage` types also enforce Dart 3 class modifiers.

## Reload and disposal

`reload()` returns raw values and notifies streams of external changes.
With the async adapter, removal notifications cover keys previously read or
written through the wrapper. Removed keys emit `null` on key streams.

Await required writes before calling `dispose()`. Disposal closes streams and
rejects queued mutations and reloads with `StateError`. Mutations and reloads
already running may finish without further notifications or logs.
Legacy factories and `.rx` remain available.

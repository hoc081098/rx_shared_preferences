# Migrating from 4.x to 5.0.0

## Update SDK and dependencies

Version 5.0.0 requires Flutter `>=3.35.0` and Dart `>=3.9.0 <4.0.0`, and uses
`rx_storage ^4.0.0`. Set `rx_shared_preferences: ^5.0.0` in `pubspec.yaml`, then
run `flutter pub get`. If your app depends directly on `rxdart_ext`, update it
to `^0.4.0` too.

## Choose your storage

The unnamed `RxSharedPreferences(...)` constructor, `getInstance()`, and the
legacy `.rx` extension are deprecated. They remain available and keep using
legacy `SharedPreferences` storage.

When adopting the new storage types, choose an entry point that matches how
your app shares the wrapper:

| Existing entry point | Entry point for new code |
| --- | --- |
| `RxSharedPreferences(prefsOrFuture)` | `.async(asyncPrefs)` or `.cached(cachedPrefsOrFuture)` |
| `RxSharedPreferences.getInstance()` | `getAsyncInstance()` or `getCachedInstance(cacheOptions: ...)` |
| `sharedPreferences.rx` | Create an async or cached wrapper and share it explicitly |

Create `SharedPreferencesAsync` for `.async` or `SharedPreferencesWithCache` for
`.cached`. All wrappers still return `Future`s from reads, including cached reads.
The [README](README.md#1-import-and-instantiate) covers construction, platform
options, cache configuration and logging.

On Android, adopting `SharedPreferencesAsync` or `SharedPreferencesWithCache`
can change the underlying storage from SharedPreferences to DataStore
Preferences. Migrate existing values with the plugin's
[data migration utility](https://pub.dev/packages/shared_preferences#migrating-from-sharedpreferences-to-sharedpreferencesasyncwithcache)
before switching your app to the new storage.

## Pass a decoder to bulk reads and streams

Replace calls to `readAll()` and `observeAll()` with an entry decoder. To keep
stored representations, use an identity decoder:

```dart
final raw = await rxPrefs.readAll((_, raw) => raw);
final changes = rxPrefs.observeAll((_, raw) => raw);
```

`EntryDecoder<String>` receives `(key, raw)` and can return a value or a `Future`.
It applies to every entry, including the initial `observeAll` snapshot. A decoded
`null` retains its key; removed entries are omitted. Bulk stream errors are
emitted as error events, and the stream keeps listening for later changes.

Custom `SharedPreferencesLike` adapters must implement this decoding contract
in `readAll`. Custom `RxSharedPreferences` implementations must also support it
in `observeAll`.

## Replace removed update methods

Replace typed `executeUpdate*` helpers with their `update*` equivalents:

```dart
await rxPrefs.updateInt('count', (current) => (current ?? 0) + 1);
```

Replace generic `executeUpdate` with `update`, using named arguments:

```dart
await rxPrefs.update<int>(
  key: 'count',
  decoder: (raw) => raw as int?,
  transformer: (current) => (current ?? 0) + 1,
  encoder: (value) => value,
);
```

Transformers can return a value or a `Future`. Updates remain experimental.

## Adapt custom implementations

Version 5.0.0 uses Dart class modifiers for its public contracts:

- Use `implements` for `SharedPreferencesLike`, `RxSharedPreferences`, and
  `RxSharedPreferencesLogger`; each is an `abstract interface class`.
- Extend `RxSharedPreferencesDefaultLogger` with a `base`, `final`, or `sealed`
  subclass, or implement `RxSharedPreferencesLogger` for custom logging.
- `RxSharedPreferencesEmptyLogger`, `ReloadSuccessEvent`, and
  `ReloadFailureEvent` are `final` and cannot be extended or implemented.
- Re-exported `rx_storage` types also enforce Dart 3 class modifiers.

A custom storage adapter can be passed directly, or as an initialization future,
to `RxSharedPreferences.custom`. See the
[custom implementation guide](README.md#8-custom-implementations-and-loggers)
for an adapter example and logger setup.

## Account for reload and disposal behavior

`reload()` returns raw stored values and notifies streams of external changes.
Key streams now emit `null` for entries removed since earlier reads or writes
through the wrapper, including when using async storage.

Await required writes before calling `dispose()`. Disposal closes streams and
rejects new or queued mutations and reloads with `StateError`. Mutations and
reloads already running may finish without further notifications or logs.
Disposing a default singleton lets its factory create a new instance on the next
call.

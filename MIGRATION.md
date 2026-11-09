# Migrating from 4.x to 5.0.0

## Update SDK and dependencies

Version 5.0.0 requires Flutter `>=3.35.0` and Dart `>=3.9.0 <4.0.0`. It uses
`rx_storage ^4.0.0`. Set `rx_shared_preferences: ^5.0.0` in `pubspec.yaml` and
update any direct `rxdart_ext` dependency to `^0.4.0`. Then run `flutter pub get`.

## Choose your storage

The unnamed constructor, `getInstance()`, and `.rx` are deprecated and still
use legacy `SharedPreferences` storage. If you switch to async or cached storage,
choose an entry point based on how you share the wrapper:

| Existing entry point | Entry point for new code |
| --- | --- |
| `RxSharedPreferences(prefsOrFuture)` | `.async(asyncPrefs)` or `.cached(cachedPrefsOrFuture)` |
| `RxSharedPreferences.getInstance()` | `getAsyncInstance()` or `getCachedInstance(cacheOptions: ...)` |
| `sharedPreferences.rx` | Create an async or cached wrapper and share it explicitly |

Wrap `SharedPreferencesAsync` with `.async` and `SharedPreferencesWithCache`
with `.cached`. Reads through either wrapper return `Future`s. See the
[README](README.md#1-import-and-instantiate) for options, caching and logging.

On Android, async and cached storage can use DataStore Preferences. Migrate
existing values with the plugin's
[data migration utility](https://pub.dev/packages/shared_preferences#migrating-from-sharedpreferences-to-sharedpreferencesasyncwithcache)
before switching from legacy storage.

## Decode bulk reads and reloads

`readAll` and `observeAll` now require an `EntryDecoder<String>`. It receives
`(key, raw)` and can return a value or a `Future`. Use `(_, raw) => raw` to keep
raw values.

`observeAll` decodes each snapshot, including the first. It emits read or decoder
errors and keeps listening.

`reload()` still returns raw values and notifies streams of external changes.
When key streams expect decoded values, reuse the entry decoder from bulk reads:

```dart
Object? decodeEntry(String key, Object? raw) =>
    key == 'encoded_count' && raw is String ? int.parse(raw) : raw;

final decoded = await rxPrefs.readAll(decodeEntry);
final decodedChanges = rxPrefs.observeAll(decodeEntry);
final refreshed = await rxPrefs.reload(decodeEntry);
```

`reload` sends the map values directly to key streams, so match the types used
by writes and `observe`. A per-key `observe` decoder runs only on the initial
read.

Decoding to `null` keeps the key in the map. Removed keys skip decoding and are
omitted. Reload emits `null` for previously known keys that are now missing,
including on async storage.

`reload` fails on the first decoder error and emits no notifications. Other
decoders keep running, and the cache may already have refreshed. A later
successful reload still reports removals.

## Replace removed update methods

Use `update*` in place of typed `executeUpdate*` helpers:

```dart
await rxPrefs.updateInt('count', (current) => (current ?? 0) + 1);
```

The generic `update` replaces `executeUpdate` and takes named arguments:

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

In custom `SharedPreferencesLike` adapters, accept an entry decoder in `readAll`
and keep `reload()` raw. Custom `RxSharedPreferences` implementations also need
a decoder in `observeAll` and the signature `reload([EntryDecoder<String>? decoder])`.

Dart 3 class modifiers also affect custom implementations:

- Use `implements` for `SharedPreferencesLike`, `RxSharedPreferences`, and
  `RxSharedPreferencesLogger`. Each is an `abstract interface class`.
- Extend `RxSharedPreferencesDefaultLogger` with a `base`, `final`, or `sealed`
  subclass, or implement `RxSharedPreferencesLogger` for custom logging.
- `RxSharedPreferencesEmptyLogger`, `ReloadSuccessEvent`, and
  `ReloadFailureEvent` are `final` and cannot be extended or implemented.
- Re-exported `rx_storage` types also enforce Dart 3 class modifiers.

Pass the adapter or its initialization future to `RxSharedPreferences.custom`.
See the [custom implementation guide](README.md#8-custom-implementations-and-loggers)
for an adapter example and logger setup.

## Manage reload and disposal

`reload` shares a queue with `clear`, so its decoder must not await either
operation on the same instance. Per-key writes can interleave with reload.

Await required writes before `dispose()`. Disposal closes streams and rejects
new or queued mutations and reloads with `StateError`. Running work can finish
without further notifications or logs. The next factory call after disposing a
default singleton creates a new instance.

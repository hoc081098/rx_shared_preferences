# Migrating from 4.x to 5.0.0

Version 5.0.0 uses `rx_storage ^4.0.0` and requires Flutter `>=3.35.0`
with Dart `>=3.9.0 <4.0.0`. Update the package constraint and run
`flutter pub get`. If your app depends directly on `rxdart_ext`, update its
constraint to `^0.4.0` as well.

## Bulk reads and streams require a decoder

Replace raw bulk reads and streams with an identity entry decoder:

```dart
final raw = await rxPrefs.readAll((_, raw) => raw);
final changes = rxPrefs.observeAll((_, raw) => raw);
```

The callback has type `EntryDecoder<String>`:

```dart
typedef EntryDecoder<Key extends Object> =
    FutureOr<Object?> Function(Key key, Object? value);
```

It can select a codec using the key and return synchronous or asynchronous
results. For example:

```dart
final values = await rxPrefs.readAll((key, raw) {
  if (key == 'name' && raw is String) return raw.toUpperCase();
  return raw;
});

final changes = rxPrefs.observeAll((key, raw) async {
  if (key == 'name' && raw is String) return raw.toUpperCase();
  return raw;
});
```

Only existing entries are decoded. A decoded null retains its key, whereas
removing a key omits it from subsequent maps. Writing an encoded null through
the shared preferences adapters still removes the key.

Custom adapters must implement
`readAll(EntryDecoder<String> decoder, [void options])`, supporting both sync
and async decoding. Custom reactive implementations must also implement
`observeAll(EntryDecoder<String> decoder, [void options])`. Report read and
decoding failures through the Future or stream, without returning partial maps.
The bundled adapters decode shallow entry snapshots; callbacks may run
concurrently. `getKeys()`, `getKeysStream()`, and `reload()` keep their signatures.

## Replace removed update methods

| Removed method | Replacement |
| --- | --- |
| `executeUpdateBool` | `updateBool` |
| `executeUpdateDouble` | `updateDouble` |
| `executeUpdateInt` | `updateInt` |
| `executeUpdateString` | `updateString` |
| `executeUpdateStringList` | `updateStringList` |
| Inherited `executeUpdate` | `update` with named arguments |

```dart
await rxPrefs.updateInt('count', (current) async => (current ?? 0) + 1);

await rxPrefs.update<int>(
  key: 'count',
  decoder: (raw) => raw as int?,
  transformer: (current) async => (current ?? 0) + 1,
  encoder: (value) => value,
);
```

Updates remain experimental. They serialize with writes and removals for the
same key on the same wrapper. Reads, clears, reloads, other keys, and other
wrappers do not participate in that per-key queue.

## Update custom class declarations

- Implement `SharedPreferencesLike`, `RxSharedPreferences`, and
  `RxSharedPreferencesLogger`; these are now `abstract interface` classes.
- Extend `RxSharedPreferencesDefaultLogger` to reuse its implementation.
  Mark subclasses as `base`, `final`, or `sealed`. The default logger can
  no longer be implemented outside its defining library.
- `RxSharedPreferencesEmptyLogger` is now final. It cannot be extended or
  implemented; implement `RxSharedPreferencesLogger` for custom logging behavior.
- `ReloadSuccessEvent` and `ReloadFailureEvent` are now final. Implement
  `RxStorageLoggerEvent<String, void>` for custom events.
- Re-exported upstream contracts (`Storage`, `TransactionalStorage`, `RxStorage`,
  `RxStorageLogger`, and `RxStorageLoggerEvent`) are also interfaces. Upstream
  `RealRxStorage` and built-in loggers are base classes; `KeyAndValue`,
  `RxStorageError`, and concrete upstream events are final.

```dart
final class AppLogger extends RxSharedPreferencesDefaultLogger {
  const AppLogger() : super(tag: 'App preferences');
}

final class MetricsLogger implements RxSharedPreferencesLogger {
  @override
  void log(RxStorageLoggerEvent<String, void> event) {
    // Handle storage events, including ReloadSuccessEvent and ReloadFailureEvent.
  }
}
```

## Reload and disposal

`reload()` returns raw values and emits notifications for external changes.
Async wrappers now also notify key streams when a previously read or written
key was removed externally. Removed keys emit null on their key streams and
are omitted from bulk maps. Call reload explicitly to observe external changes.

Await required mutations before disposal. Queued mutations and reloads that
have not started fail with `StateError`; operations that already started can
finish without further change notifications or logs. Repeated `dispose()` calls
share their result and run external cleanup at most once. Initialization errors
from adapter futures are retained for subsequent operations.

The legacy constructors and `.rx` extension remain available. For new code,
consider `getAsyncInstance()`, `getWithCacheInstance()`, or the experimental
`RxSharedPreferences.async` and `RxSharedPreferences.withCache` factories.

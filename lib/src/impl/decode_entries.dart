import 'dart:async';

import 'package:rx_storage/rx_storage.dart' show EntryDecoder;

/// Reads a shallow entry snapshot and decodes it into a new map.
///
/// Reading and decoding failures complete the returned future with an error.
/// The first decoder error is reported immediately; other decoders keep running.
/// Entry decoders may run concurrently; null results retain their keys.
Future<Map<String, Object?>> readAllDecoded(
  FutureOr<Map<String, Object?>> Function() readRaw,
  EntryDecoder<String> decoder,
) => Future.sync(readRaw).then((values) {
  final entries = values.entries.toList(growable: false);

  return Future.wait(
    entries.map(
      (entry) => Future<Object?>.sync(
        () => decoder(entry.key, entry.value),
      ).then((value) => MapEntry(entry.key, value)),
    ),
    eagerError: true,
  ).then((decoded) => Map<String, Object?>.fromEntries(decoded));
});

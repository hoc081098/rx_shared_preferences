import 'package:rx_storage/rx_storage.dart' show RxStorageEmptyLogger;

import 'logger.dart';

/// Discards all storage and reload log events.
final class RxSharedPreferencesEmptyLogger
    extends RxStorageEmptyLogger<String, void>
    implements RxSharedPreferencesLogger {
  /// Constructs a [RxSharedPreferencesEmptyLogger].
  const RxSharedPreferencesEmptyLogger();
}

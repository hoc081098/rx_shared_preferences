import 'package:rx_storage/rx_storage.dart' show RxStorageEmptyLogger;

import 'logger.dart';

/// A no-op [RxSharedPreferencesLogger].
final class RxSharedPreferencesEmptyLogger
    extends RxStorageEmptyLogger<String, void>
    implements RxSharedPreferencesLogger {
  /// Constructs a [RxSharedPreferencesEmptyLogger].
  const RxSharedPreferencesEmptyLogger();
}

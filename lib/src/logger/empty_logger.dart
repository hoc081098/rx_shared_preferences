import 'package:rx_storage/rx_storage.dart' show RxStorageEmptyLogger;

import 'logger.dart';

/// Log nothing :)
class RxSharedPreferencesEmptyLogger extends RxStorageEmptyLogger<String, void>
    implements RxSharedPreferencesLogger {
  /// Constructs a [RxSharedPreferencesEmptyLogger].
  const RxSharedPreferencesEmptyLogger();
}

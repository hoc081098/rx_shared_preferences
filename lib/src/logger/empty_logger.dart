import 'package:rx_storage/rx_storage.dart' show EmptyLogger;

import 'logger.dart';

/// Log nothing :)
class RxSharedPreferencesEmptyLogger extends EmptyLogger<String, void>
    implements RxSharedPreferencesLogger {
  /// Constructs a [RxSharedPreferencesEmptyLogger].
  const RxSharedPreferencesEmptyLogger();
}

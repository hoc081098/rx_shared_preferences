import 'package:rx_storage/rx_storage.dart'
    show Logger, LoggerEvent, RxStorageError, KeyAndValue;

/// Log messages about operations (such as read, write, value change) and stream events.
abstract class RxSharedPreferencesLogger extends Logger<String, void> {}

/// Reload successfully.
class ReloadSuccessEvent implements LoggerEvent<String, void> {
  /// A list containing all values after reload.
  final List<KeyAndValue<String, Object?>> pairs;

  /// Construct a [ReloadSuccessEvent].
  ReloadSuccessEvent(this.pairs);
}

/// Reload failed.
class ReloadFailureEvent implements LoggerEvent<String, void> {
  /// The error occurred when reloading.
  final RxStorageError error;

  /// Construct a [ReloadFailureEvent].
  ReloadFailureEvent(this.error);
}

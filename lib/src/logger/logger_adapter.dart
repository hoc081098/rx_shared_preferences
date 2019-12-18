import 'package:rx_shared_preferences/src/logger/logger.dart';
import 'package:rx_shared_preferences/src/model/key_and_value.dart';

///
/// Logger's implementation with empty methods
///
class LoggerAdapter implements Logger {
  ///
  /// Constructs a [LoggerAdapter]
  ///
  const LoggerAdapter();

  @override
  void doOnDataStream(KeyAndValue pair) {}

  @override
  void doOnErrorStream(error, StackTrace stackTrace) {}

  @override
  void keysChanged(Iterable<KeyAndValue> pairs) {}

  @override
  void readValue(Type type, String key, value) {}

  @override
  void writeValue(Type type, String key, value, bool writeResult) {}
}

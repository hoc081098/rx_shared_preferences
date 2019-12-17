import 'package:rx_shared_preferences/rx_shared_preferences.dart';

//
// Using logger:
// 1. extends DefaultLogger
// 2. implements Logger
//

/// Emtpy logger
class EmptyLogger extends DefaultLogger {
  /// Override method you want
}

/// Implements all methods
class CustomLogger implements Logger {
  @override
  void doOnDataStream(KeyAndValue pair) => print(pair);

  @override
  void doOnErrorStream(error, StackTrace stackTrace) => print(error);

  @override
  void keysChanged(Iterable<KeyAndValue> pairs) => print(pairs);

  @override
  void readValue(Type type, String key, value) => print(value);

  @override
  void writeValue(Type type, String key, value, bool writeResult) =>
      print(writeResult);
}

/// Or using default logger
const defaultLogger = DefaultLogger();

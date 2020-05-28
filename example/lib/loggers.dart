import 'package:rx_shared_preferences/rx_shared_preferences.dart';

//
// Using logger:
// 1. extends LoggerAdapter
// 2. implements Logger
//

/// Empty logger
class EmptyLogger extends LoggerAdapter {
  /// Override methods you want
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
  void readValue(Type type, String key, dynamic value) => print(value);

  @override
  void writeValue(Type type, String key, dynamic value, bool writeResult) =>
      print(writeResult);
}

/// Or using default logger
const defaultLogger = DefaultLogger();

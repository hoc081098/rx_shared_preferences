import 'package:rx_shared_preference/src/logger/logger.dart';
import 'package:rx_shared_preference/src/model/key_and_value.dart';

///
/// 
///
class LoggerAdapter implements Logger {
  const LoggerAdapter();
  
  @override
  void doOnDataObservable(KeyAndValue pair) {}

  @override
  void doOnErrorObservable(error, StackTrace stackTrace) {}

  @override
  void keysChanged(Iterable<KeyAndValue> pairs) {}

  @override
  void readValue(Type type, String key, value) {}

  @override
  void writeValue(Type type, String key, value, bool writeResult) {}
}

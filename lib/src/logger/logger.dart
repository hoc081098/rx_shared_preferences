import 'package:rx_shared_preferences/src/model/key_and_value.dart';

abstract class Logger {
  void keysChanged(Iterable<KeyAndValue<dynamic>> pairs);
  void doOnDataObservable(KeyAndValue pair);
  void doOnErrorObservable(dynamic error, StackTrace stackTrace);
  void readValue(Type type, String key, dynamic value);
  void writeValue(Type type, String key, dynamic value, bool writeResult);
}

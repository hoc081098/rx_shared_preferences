import 'package:rx_shared_preference/src/logger/logger.dart';
import 'package:rx_shared_preference/src/model/key_and_value.dart';

class DefaultLogger implements Logger {
  const DefaultLogger();

  @override
  void keysChanged(Iterable<KeyAndValue> pairs) =>
      print('[KEYS_CHANGED       ] pairs=$pairs');

  @override
  void doOnDataObservable(KeyAndValue pair) =>
      print('[ON_DATA_OBSERAVBLE ] data=$pair');

  @override
  void doOnErrorObservable(error, StackTrace stackTrace) =>
      print('[ON_ERROR_OBSERVABLE] error=$error, stackTrace=$stackTrace');

  @override
  void readValue(Type type, String key, value) =>
      print("[READ_VALUE         ] type=$type, key='$key', value=$value");

  @override
  void writeValue(Type type, String key, value, bool writeResult) =>
      print("[WRITE_VALUE        ] type=$type, key='$key', "
          'value=$value, writeResult=$writeResult');
}

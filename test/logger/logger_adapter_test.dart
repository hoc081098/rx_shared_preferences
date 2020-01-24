import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';

void main() {
  group('LoggerAdapter', () {
    test('Works', () {
      const logger = LoggerAdapter();
      const keyAndValue = KeyAndValue('key', 'value');
      logger.keysChanged([keyAndValue]);
      logger.doOnDataStream(keyAndValue);
      logger.doOnErrorStream(Exception(), StackTrace.current);
      logger.writeValue(
        keyAndValue.value.runtimeType,
        keyAndValue.key,
        keyAndValue.value,
        true,
      );
      logger.readValue(
        keyAndValue.value.runtimeType,
        keyAndValue.key,
        keyAndValue.value,
      );
    });
  });
}

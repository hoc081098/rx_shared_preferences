import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/src/model/key_and_value.dart';

void main() {
  group('$KeyAndValue tests', () {
    test('Construct a KeyAndValue', () {
      KeyAndValue('key1', 'value');
      KeyAndValue('key2', 2);
      KeyAndValue('key3', 2.5);
      KeyAndValue('key4', true);
      KeyAndValue('key5', null);
      KeyAndValue('key6', <String>['v1', 'v2', 'v3']);
      expect(true, isTrue);
    });

    test('KeyAndValue.toString', () {
      expect(
        KeyAndValue('key1', 'value').toString(),
        "{ 'key1': value }",
      );
      expect(
        KeyAndValue('key2', 2).toString(),
        "{ 'key2': 2 }",
      );
      expect(
        KeyAndValue('key3', 2.5).toString(),
        "{ 'key3': 2.5 }",
      );
      expect(
        KeyAndValue('key4', true).toString(),
        "{ 'key4': true }",
      );
      expect(
        KeyAndValue('key5', null).toString(),
        "{ 'key5': null }",
      );
      expect(
        KeyAndValue('key6', <String>['v1', 'v2', 'v3']).toString(),
        "{ 'key6': [v1, v2, v3] }",
      );
    });
  });
}

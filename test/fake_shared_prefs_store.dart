import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import 'model/user.dart';

final throwsPlatformException = throwsA(isA<PlatformException>());

final kTestValues = <String, Object>{
  'flutter.String': 'hello world',
  'flutter.bool': true,
  'flutter.int': 42,
  'flutter.double': 3.14159,
  'flutter.List': <String>['foo', 'bar'],
  'flutter.User': jsonEncode(user1),
};

final kTestValues2 = <String, Object>{
  'flutter.String': 'goodbye world',
  'flutter.bool': false,
  'flutter.int': 1337,
  'flutter.double': 2.71828,
  'flutter.List': <String>['baz', 'quox'],
  'flutter.User': jsonEncode(user2),
};

/// Fake Shared Preferences Store
class FakeSharedPreferencesStore extends SharedPreferencesStorePlatform
    implements MockPlatformInterfaceMixin {
  final InMemorySharedPreferencesStore backend;
  final log = <MethodCall>[];

  MethodCall? failedMethod;

  FakeSharedPreferencesStore(Map<String, Object> data)
      : backend = InMemorySharedPreferencesStore.withData(data);

  @override
  Future<bool> clear() {
    if (failedMethod?.method == 'clear') {
      return Future.value(false);
    }
    log.add(const MethodCall('clear'));
    return backend.clear();
  }

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) {
    if (failedMethod?.method == 'clearWithParameters') {
      return Future.value(false);
    }
    log.add(const MethodCall('clearWithParameters'));
    return backend.clearWithParameters(parameters);
  }

  @override
  Future<Map<String, Object>> getAll() {
    if (failedMethod?.method == 'getAll') {
      return Future.error(
        PlatformException(code: 'error', message: 'Cannot getAll'),
      );
    }
    log.add(const MethodCall('getAll'));
    return backend.getAll();
  }

  @override
  Future<Map<String, Object>> getAllWithParameters(
      GetAllParameters parameters) {
    if (failedMethod?.method == 'getAllWithParameters') {
      return Future.error(
        PlatformException(
            code: 'error', message: 'Cannot getAllWithParameters'),
      );
    }
    log.add(const MethodCall('getAllWithParameters'));
    return backend.getAllWithParameters(parameters);
  }

  @override
  Future<bool> remove(String key) {
    if (failedMethod?.method == 'remove') {
      return Future.value(false);
    }
    log.add(MethodCall('remove', key));
    return backend.remove(key);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    if (failedMethod?.method == 'setValue') {
      return Future.value(false);
    }
    log.add(MethodCall('setValue', [valueType, key, value]));
    return backend.setValue(valueType, key, value);
  }
}

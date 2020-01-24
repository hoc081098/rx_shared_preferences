import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Fake Shared Preferences Store
class FakeSharedPreferencesStore implements SharedPreferencesStorePlatform {
  final InMemorySharedPreferencesStore backend;
  final log = <MethodCall>[];

  FakeSharedPreferencesStore(Map<String, dynamic> data)
      : backend = InMemorySharedPreferencesStore.withData(data);

  @override
  bool get isMock => true;

  @override
  Future<bool> clear() {
    log.add(MethodCall('clear'));
    return backend.clear();
  }

  @override
  Future<Map<String, Object>> getAll() {
    log.add(MethodCall('getAll'));
    return backend.getAll();
  }

  @override
  Future<bool> remove(String key) {
    log.add(MethodCall('remove', key));
    return backend.remove(key);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    log.add(MethodCall('setValue', [valueType, key, value]));
    return backend.setValue(valueType, key, value);
  }
}

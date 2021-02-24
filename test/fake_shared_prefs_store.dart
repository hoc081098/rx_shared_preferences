import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Fake Shared Preferences Store
class FakeSharedPreferencesStore implements SharedPreferencesStorePlatform {
  final InMemorySharedPreferencesStore backend;
  final log = <MethodCall>[];

  MethodCall? failedMethod;

  FakeSharedPreferencesStore(Map<String, Object> data)
      : backend = InMemorySharedPreferencesStore.withData(data);

  @override
  bool get isMock => true;

  @override
  Future<bool> clear() {
    if (failedMethod?.method == 'clear') {
      return Future.value(false);
    }
    log.add(MethodCall('clear'));
    return backend.clear();
  }

  @override
  Future<Map<String, Object>> getAll() {
    if (failedMethod?.method == 'getAll') {
      return Future.error(
        PlatformException(code: 'error', message: 'Cannot getAll'),
      );
    }
    log.add(MethodCall('getAll'));
    return backend.getAll();
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

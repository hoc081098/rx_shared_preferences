import 'dart:async';

import '../../rx_shared_preferences.dart';
import '../interface/rx_shared_preferences.dart';

/// Default [RxSharedPreferences] implementation
class RealRxSharedPreferences implements RxSharedPreferences {
  final RxStorage _delegate;

  ///
  RealRxSharedPreferences(
    FutureOr<SharedPreferencesLike> sharedPreferencesLikeOrFuture, [
    Logger logger,
    void Function() onDispose,
  ]) : _delegate = RxStorage(sharedPreferencesLikeOrFuture, logger, onDispose);

  @override
  Future<bool> clear() => _delegate.clear();

  @override
  Future<bool> containsKey(String key) => _delegate.containsKey(key);

  @override
  Future<void> dispose() => _delegate.dispose();

  @override
  Future get(String key) => _delegate.get(key);

  @override
  Future<bool> getBool(String key) => _delegate.getBool(key);

  @override
  Stream<bool> getBoolStream(String key) => _delegate.getBoolStream(key);

  @override
  Future<double> getDouble(String key) => _delegate.getDouble(key);

  @override
  Stream<double> getDoubleStream(String key) => _delegate.getDoubleStream(key);

  @override
  Future<int> getInt(String key) => _delegate.getInt(key);

  @override
  Stream<int> getIntStream(String key) => _delegate.getIntStream(key);

  @override
  Future<Set<String>> getKeys() => _delegate.getKeys();

  @override
  Stream<Set<String>> getKeysStream() => _delegate.getKeysStream();

  @override
  Stream getStream(String key) => _delegate.getStream(key);

  @override
  Future<String> getString(String key) => _delegate.getString(key);

  @override
  Future<List<String>> getStringList(String key) =>
      _delegate.getStringList(key);

  @override
  Stream<List<String>> getStringListStream(String key) =>
      _delegate.getStringListStream(key);

  @override
  Stream<String> getStringStream(String key) => _delegate.getStringStream(key);

  @override
  Future<void> reload() => _delegate.reload();

  @override
  Future<bool> remove(String key) => _delegate.remove(key);

  @override
  Future<bool> setBool(String key, bool value) => _delegate.setBool(key, value);

  @override
  Future<bool> setDouble(String key, double value) =>
      _delegate.setDouble(key, value);

  @override
  Future<bool> setInt(String key, int value) => _delegate.setInt(key, value);

  @override
  Future<bool> setString(String key, String value) =>
      _delegate.setString(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _delegate.setStringList(key, value);
}

import 'dart:async';

import 'package:rx_storage/rx_storage.dart';

import '../../rx_shared_preferences.dart';
import '../interface/rx_shared_preferences.dart';

T _identity<T>(T t) => t;

/// Default [RxSharedPreferences] implementation
class RealRxSharedPreferences extends RealRxStorage<String>
    implements RxSharedPreferences {
  final Logger _logger;
  final FutureOr<SharedPreferencesLike> _prefsLikeOrFuture;

  ///
  RealRxSharedPreferences(
    this._prefsLikeOrFuture, [
    Logger logger,
    void Function() onDispose,
  ])  : _logger = logger,
        super(_prefsLikeOrFuture, logger, onDispose);

  @override
  Future<dynamic> get(String key) => read(key, _identity);

  @override
  Future<bool> getBool(String key) => read(key, (s) => s as bool);

  @override
  Future<double> getDouble(String key) => read(key, (s) => s as double);

  @override
  Future<int> getInt(String key) => read(key, (s) => s as int);

  @override
  Future<Set<String>> getKeys() =>
      readAll().then((value) => value.keys.toSet());

  @override
  Future<String> getString(String key) => read(key, (s) => s as String);

  @override
  Future<List<String>> getStringList(String key) =>
      read(key, (s) => s as List<String>);

  @override
  Future<bool> setBool(String key, bool value) => write(key, value, _identity);

  @override
  Future<bool> setDouble(String key, double value) =>
      write(key, value, _identity);

  @override
  Future<bool> setInt(String key, int value) => write(key, value, _identity);

  @override
  Future<bool> setString(String key, String value) =>
      write(key, value, _identity);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      write(key, value, _identity);

  //
  //
  //

  @override
  Stream<dynamic> getStream(String key) => observe(key, _identity);

  @override
  Stream<bool> getBoolStream(String key) => observe(key, (s) => s as bool);

  @override
  Stream<double> getDoubleStream(String key) =>
      observe(key, (s) => s as double);

  @override
  Stream<int> getIntStream(String key) => observe(key, (s) => s as int);

  @override
  Stream<String> getStringStream(String key) =>
      observe(key, (s) => s as String);

  @override
  Stream<List<String>> getStringListStream(String key) =>
      observe(key, (s) => s as List<String>);

  @override
  Stream<Set<String>> getKeysStream() =>
      observeAll().map((event) => event.keys.toSet());

  @override
  Future<void> reload() async {
    final prefs = _prefsLikeOrFuture is Future<SharedPreferencesLike>
        ? await _prefsLikeOrFuture
        : _prefsLikeOrFuture as SharedPreferencesLike;
    await prefs.reload();

    final keys = await prefs.getKeys();

    // Read new values from storage.
    final map = {for (final k in keys) k: await prefs.get(k)};
    if (_logger != null) {
      for (final key in keys) {
        _logger.readValue(dynamic, key, map[key]);
      }
    }
    sendChange(map);
  }
}

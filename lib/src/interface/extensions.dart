import 'package:meta/meta.dart';

import '../../rx_shared_preferences.dart';

T _identity<T>(T t) => t;

T _cast<T>(Object? value) => value as T;

/// Extensions for primitive type
extension SharedPreferencesExtensions on SharedPreferencesLike {
  /// Reads a value of any type from persistent storage.
  Future<Object?> getObject(String key, [Decoder<Object?>? decoder]) =>
      read<Object>(key, decoder ?? _identity);

  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a bool.
  Future<bool?> getBool(String key) => read<bool>(key, _cast);

  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a double.
  Future<double?> getDouble(String key) => read<double>(key, _cast);

  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a int.
  Future<int?> getInt(String key) => read<int>(key, _cast);

  /// Returns all keys in the persistent storage.
  Future<Set<String>> getKeys() => readAll().then((map) => map.keys.toSet());

  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a String.
  Future<String?> getString(String key) => read<String>(key, _cast);

  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a string set.
  Future<List<String>?> getStringList(String key) =>
      read<List<String>>(key, _cast);

  /// Saves a boolean [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  Future<void> setBool(String key, bool? value) =>
      write<bool>(key, value, _identity);

  /// Saves a double [value] to persistent storage in the background.
  ///
  /// Android doesn't support storing doubles, so it will be stored as a float.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  Future<void> setDouble(String key, double? value) =>
      write<double>(key, value, _identity);

  /// Saves an integer [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  Future<void> setInt(String key, int? value) =>
      write<int>(key, value, _identity);

  /// Saves a string [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  Future<void> setString(String key, String? value) =>
      write<String>(key, value, _identity);

  /// Saves a list of strings [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  Future<void> setStringList(String key, List<String>? value) =>
      write<List<String>>(key, value, _identity);
}

/// Extensions for primitive type
extension RxSharedPreferencesExtension on RxSharedPreferences {
  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with key was changed.
  Stream<Object?> getObjectStream(String key, [Decoder<Object?>? decoder]) =>
      observe<Object>(key, decoder ?? _identity);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a bool.
  Stream<bool?> getBoolStream(String key) => observe<bool>(key, _cast);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a double.
  Stream<double?> getDoubleStream(String key) => observe<double>(key, _cast);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a int.
  Stream<int?> getIntStream(String key) => observe<int>(key, _cast);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a String.
  Stream<String?> getStringStream(String key) => observe<String>(key, _cast);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a string set.
  Stream<List<String>?> getStringListStream(String key) =>
      observe<List<String>>(key, _cast);

  /// Return [Stream] that will emit all keys read from persistent storage.
  /// It will automatic emit all keys when any value was changed.
  Stream<Set<String>> getKeysStream() =>
      observeAll().map((map) => map.keys.toSet());

  /// `Read–modify–write`.
  ///
  /// Read bool value by [key],
  /// then transforming the value by [transformer],
  /// and finally save transformed value to persistent storage.
  ///
  /// Use [updateBool] instead. It will be removed in v4.0.0.
  ///
  /// See also:
  ///   * [update] for more details.
  ///   * [updateBool].
  @experimental
  @Deprecated('Use updateBool instead. It will be removed in v4.0.0')
  Future<void> executeUpdateBool(String key, Transformer<bool?> transformer) =>
      updateBool(key, transformer);

  /// `Read–modify–write`.
  ///
  /// Read bool value by [key],
  /// then transforming the value by [transformer],
  /// and finally save transformed value to persistent storage.
  ///
  /// See also:
  ///   * [update] for more details.
  @experimental
  Future<void> updateBool(String key, Transformer<bool?> transformer) =>
      update<bool>(
        key: key,
        decoder: _cast,
        transformer: transformer,
        encoder: _identity,
      );

  /// `Read–modify–write`.
  ///
  /// Read double value by [key],
  /// then transforming the value by [transformer],
  /// and finally save transformed value to persistent storage.
  ///
  /// Use [updateDouble] instead. It will be removed in v4.0.0.
  ///
  /// See also:
  ///   * [update] for more details.
  ///   * [updateDouble].
  @experimental
  @Deprecated('Use updateDouble instead. It will be removed in v4.0.0')
  Future<void> executeUpdateDouble(
          String key, Transformer<double?> transformer) =>
      updateDouble(key, transformer);

  /// `Read–modify–write`.
  ///
  /// Read double value by [key],
  /// then transforming the value by [transformer],
  /// and finally save transformed value to persistent storage.
  ///
  /// See also:
  ///   * [update] for more details.
  @experimental
  Future<void> updateDouble(String key, Transformer<double?> transformer) =>
      update<double>(
        key: key,
        decoder: _cast,
        transformer: transformer,
        encoder: _identity,
      );

  /// `Read–modify–write`.
  ///
  /// Read int value by [key],
  /// then transforming the value by [transformer],
  /// and finally save transformed value to persistent storage.
  ///
  /// Use [updateInt] instead. It will be removed in v4.0.0.
  ///
  /// See also:
  ///   * [update] for more details.
  ///   * [updateInt].
  @experimental
  @Deprecated('Use updateInt instead. It will be removed in v4.0.0')
  Future<void> executeUpdateInt(String key, Transformer<int?> transformer) =>
      updateInt(key, transformer);

  /// `Read–modify–write`.
  ///
  /// Read int value by [key],
  /// then transforming the value by [transformer],
  /// and finally save transformed value to persistent storage.
  ///
  /// See also:
  ///   * [update] for more details.
  @experimental
  Future<void> updateInt(String key, Transformer<int?> transformer) =>
      update<int>(
        key: key,
        decoder: _cast,
        transformer: transformer,
        encoder: _identity,
      );

  /// `Read–modify–write`.
  ///
  /// Read String value by [key], than transform value by [transformer]
  /// and finally save computed value to persistent storage.
  @experimental
  Future<void> executeUpdateString(
    String key,
    Transformer<String?> transformer,
  ) =>
      update<String>(
        key: key,
        decoder: _cast,
        transformer: transformer,
        encoder: _identity,
      );

  /// `Read–modify–write`.
  ///
  /// Read List<String> value by [key], than transform value by [transformer]
  /// and finally save computed value to persistent storage.
  @experimental
  Future<void> executeUpdateStringList(
    String key,
    Transformer<List<String>?> transformer,
  ) =>
      update<List<String>>(
        key: key,
        decoder: _cast,
        transformer: transformer,
        encoder: _identity,
      );
}

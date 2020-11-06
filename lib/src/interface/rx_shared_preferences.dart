import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../rx_shared_preferences.dart';
import '../adapters/shared_preferences_adapter.dart';
import '../impl/real_rx_shared_preferences.dart';
import '../logger/logger.dart';
import 'shared_preferences_like.dart';

///
/// Get [Stream]s by key from persistent storage.
///
abstract class RxSharedPreferences implements SharedPreferencesLike {
  static RealRxSharedPreferences _defaultInstance;

  ///
  /// Return default singleton instance
  ///
  factory RxSharedPreferences.getInstance() =>
      _defaultInstance ??= RxSharedPreferences(
        SharedPreferences.getInstance(),
        RxSharedPreferencesConfigs.logger,
        () => _defaultInstance = null,
      );

  ///
  /// Construct a [RxSharedPreferences] with [SharedPreferences] and optional [Logger]
  ///
  factory RxSharedPreferences(
    FutureOr<SharedPreferences> prefsOrFuture, [
    Logger logger,
    void Function() onDispose,
  ]) =>
      RxSharedPreferences.from(
        SharedPreferencesAdapter.from(prefsOrFuture),
        logger,
        onDispose,
      );

  /// TODO
  factory RxSharedPreferences.from(
    FutureOr<SharedPreferencesLike> sharedPreferencesLikeOrFuture, [
    Logger logger,
    void Function() onDispose,
  ]) =>
      RealRxSharedPreferences(
        sharedPreferencesLikeOrFuture,
        logger,
        onDispose,
      );

  ///
  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with key was changed.
  ///
  Stream<dynamic> getStream(String key);

  ///
  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a bool.
  ///
  Stream<bool> getBoolStream(String key);

  ///
  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a double.
  ///
  Stream<double> getDoubleStream(String key);

  ///
  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a int.
  ///
  Stream<int> getIntStream(String key);

  ///
  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a String.
  ///
  Stream<String> getStringStream(String key);

  ///
  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a string set.
  ///
  Stream<List<String>> getStringListStream(String key);

  ///
  /// Return [Stream] that will emit all keys read from persistent storage.
  /// It will automatic emit all keys when any value was changed.
  ///
  Stream<Set<String>> getKeysStream();

  ///
  /// Clean up resources - Closes the streams.
  /// This method should be called when a [RxSharedPreferences] is no longer needed.
  /// Once `dispose` is called, all streams will `not` emit changed value when value changed.
  ///
  Future<void> dispose();
}

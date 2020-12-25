import 'dart:async';

import 'package:rx_storage/rx_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../rx_shared_preferences.dart';
import '../adapters/shared_preferences_adapter.dart';
import '../impl/real_rx_shared_preferences.dart';
import 'shared_preferences_like.dart';

/// Get [Stream]s by key from persistent storage.
abstract class RxSharedPreferences extends RxStorage<String>
    implements SharedPreferencesLike {
  static RxStorage _defaultInstance;

  /// Return default singleton instance.
  /// Custom logger via [RxSharedPreferencesConfigs.logger].
  factory RxSharedPreferences.getInstance() =>
      _defaultInstance ??= RxSharedPreferences(
        SharedPreferences.getInstance(),
        RxSharedPreferencesConfigs.logger,
        () => _defaultInstance = null,
      );

  /// Construct a [RxSharedPreferences] with [SharedPreferences] and optional [Logger]
  factory RxSharedPreferences(
    FutureOr<SharedPreferences> prefsOrFuture, [
    Logger logger,
    void Function() onDispose,
  ]) =>
      RealRxSharedPreferences(
        SharedPreferencesAdapter.from(prefsOrFuture),
        logger,
        onDispose,
      );

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with key was changed.
  Stream<dynamic> getStream(String key);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a bool.
  Stream<bool> getBoolStream(String key);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a double.
  Stream<double> getDoubleStream(String key);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a int.
  Stream<int> getIntStream(String key);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a String.
  Stream<String> getStringStream(String key);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a string set.
  Stream<List<String>> getStringListStream(String key);

  /// Return [Stream] that will emit all keys read from persistent storage.
  /// It will automatic emit all keys when any value was changed.
  Stream<Set<String>> getKeysStream();
}

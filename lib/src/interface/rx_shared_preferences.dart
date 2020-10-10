import 'dart:async';

import 'package:rx_shared_preferences/src/impl/real_rx_shared_preferences.dart';
import 'package:rx_shared_preferences/src/interface/shared_preferences_like.dart';
import 'package:rx_shared_preferences/src/logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

///
/// Get [Stream]s by key from persistent storage.
///
abstract class RxSharedPreferences implements SharedPreferencesLike {
  ///
  /// Construct a [RxSharedPreferences] with [SharedPreferences] and optional [Logger]
  ///
  factory RxSharedPreferences(
    FutureOr<SharedPreferences> sharedPreference, [
    Logger logger,
    void Function() onDispose,
  ]) =>
      RealRxSharedPreferences(
        sharedPreference,
        logger,
        onDispose,
      );

  ///
  /// Return default singleton instance
  ///
  factory RxSharedPreferences.getInstance() =>
      RealRxSharedPreferences.getInstance();

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

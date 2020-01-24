import 'package:rx_shared_preferences/src/interface/shared_preferences_like.dart';

///
/// Get [Stream]s by key from persistent storage.
///
abstract class IRxSharedPreferences implements ISharedPreferencesLike {
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
  /// Clean up resources - Closes the streams.
  /// This method should be called when a [IRxSharedPreferences] is no longer needed.
  /// Once `dispose` is called, all streams will `not` emit changed value when value changed, and receiver onDone event.
  ///
  Future<void> dispose();
}

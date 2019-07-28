import 'package:rxdart/rxdart.dart';

///
/// Get [Observable]s by key from persistent storage.
///
abstract class IRxSharedPreferences {
  ///
  /// Return [Observable] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with key was changed.
  ///
  Observable<dynamic> getObservable(String key);

  ///
  /// Return [Observable] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This observable will emit an error if it's not a bool.
  ///
  Observable<bool> getBoolObservable(String key);

  ///
  /// Return [Observable] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This observable will emit an error if it's not a double.
  ///
  Observable<double> getDoubleObservable(String key);

  ///
  /// Return [Observable] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This observable will emit an error if it's not a int.
  ///
  Observable<int> getIntObservable(String key);

  ///
  /// Return [Observable] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This observable will emit an error if it's not a String.
  ///
  Observable<String> getStringObservable(String key);

  ///
  /// Return [Observable] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This observable will emit an error if it's not a string set.
  ///
  Observable<List<String>> getStringListObservable(String key);
}

/// Wraps NSUserDefaults (on iOS) and SharedPreferences (on Android), providing
/// a persistent store for simple data.
///
/// Data is persisted to disk asynchronously.
abstract class SharedPreferencesLike {
  ///
  /// Returns a future complete with value true if the persistent storage
  /// contains the given [key].
  ///
  Future<bool> containsKey(String key);

  ///
  /// Reads a value of any type from persistent storage.
  ///
  Future<dynamic> get(String key);

  ///
  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a bool.
  ///
  Future<bool> getBool(String key);

  ///
  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a double.
  ///
  Future<double> getDouble(String key);

  ///
  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a int.
  ///
  Future<int> getInt(String key);

  ///
  /// Returns all keys in the persistent storage.
  ///
  Future<Set<String>> getKeys();

  ///
  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a String.
  ///
  Future<String> getString(String key);

  ///
  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a string set.
  ///
  Future<List<String>> getStringList(String key);

  ///
  /// Completes with true once the user preferences for the app has been cleared.
  ///
  Future<bool> clear();

  /// Fetches the latest values from the host platform.
  ///
  /// Use this method to observe modifications that were made in native code
  /// (without using the plugin) while the app is running.
  Future<void> reload();

  ///
  /// Removes an entry from persistent storage.
  ///
  Future<bool> remove(String key);

  ///
  /// Saves a boolean [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  ///
  Future<bool> setBool(String key, bool value);

  ///
  /// Saves a double [value] to persistent storage in the background.
  ///
  /// Android doesn't support storing doubles, so it will be stored as a float.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  ///
  Future<bool> setDouble(String key, double value);

  ///
  /// Saves an integer [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  ///
  Future<bool> setInt(String key, int value);

  ///
  /// Saves a string [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  ///
  Future<bool> setString(String key, String value);

  ///
  /// Saves a list of strings [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  ///
  Future<bool> setStringList(String key, List<String> value);
}

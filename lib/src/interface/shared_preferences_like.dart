import 'package:rx_storage/rx_storage.dart';

/// Wraps NSUserDefaults (on iOS) and SharedPreferences (on Android), providing
/// a persistent store for simple data.
///
/// Data is persisted to disk asynchronously.
abstract class SharedPreferencesLike extends Storage {}

import 'dart:async';

import 'package:rx_storage/rx_storage.dart';

import '../interface/rx_shared_preferences.dart';
import '../interface/shared_preferences_like.dart';
import '../logger/logger.dart';
import 'reloadable_shared_preferences.dart';

/// Default [RxSharedPreferences] implementation
final class RealRxSharedPreferences
    extends RealRxStorage<String, void, ReloadableSharedPreferences>
    implements RxSharedPreferences {
  ///
  RealRxSharedPreferences(
    FutureOr<SharedPreferencesLike> prefsLikeOrFuture, [
    RxSharedPreferencesLogger? logger,
    void Function()? onDispose,
  ]) : super(
         ReloadableSharedPreferences.from(prefsLikeOrFuture),
         logger,
         onDispose,
       );

  @override
  Future<Map<String, Object?>> reload() {
    return enqueueWritingTask(null, () async {
      final beforeKeys = await useStorageWithHandlers(
        (s) => s.readKeysBeforeReload(),
        null,
        null,
      );

      return useStorageWithHandlers(
        (s) => s.reload(),
        (value, _) {
          sendChange(_computeMap(beforeKeys, value));
          logIfEnabled(() => ReloadSuccessEvent(value.toListOfKeyAndValues()));
        },
        (error, _) => logIfEnabled(() => ReloadFailureEvent(error)),
      );
    });
  }

  static Map<String, KeyAndValue<String, Object?>> _computeMap(
    Set<String> beforeKeys,
    Map<String, Object?> after,
  ) {
    final deletedKeys = beforeKeys.difference(after.keys.toSet());
    return <String, Object?>{
      ...after,
      for (final k in deletedKeys) k: null,
    }.map((key, value) => MapEntry(key, KeyAndValue(key, value, dynamic)));
  }
}

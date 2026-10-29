import 'dart:async';

import 'package:rx_storage/rx_storage.dart';

import '../interface/rx_shared_preferences.dart';
import '../interface/shared_preferences_like.dart';
import '../logger/logger.dart';
import 'key_tracking_shared_preferences.dart';

/// Default [RxSharedPreferences] implementation
final class RealRxSharedPreferences
    extends RealRxStorage<String, void, KeyTrackingSharedPreferences>
    implements RxSharedPreferences {
  ///
  RealRxSharedPreferences(
    FutureOr<SharedPreferencesLike> prefsLikeOrFuture, [
    RxSharedPreferencesLogger? logger,
    void Function()? onDispose,
  ]) : super(
         KeyTrackingSharedPreferences.from(prefsLikeOrFuture),
         logger,
         onDispose,
       );

  @override
  Future<Map<String, Object?>> reload() {
    return enqueueWritingTask(null, () async {
      final result = await useStorageWithHandlers(
        (s) => s.reload(),
        (result, _) {
          sendChange({
            for (final entry in result.values.entries)
              entry.key: KeyAndValue(entry.key, entry.value, dynamic),
            for (final key in result.removedKeys)
              key: KeyAndValue(key, null, dynamic),
          });
          logIfEnabled(
            () => ReloadSuccessEvent(result.values.toListOfKeyAndValues()),
          );
        },
        (error, _) => logIfEnabled(() => ReloadFailureEvent(error)),
      );
      return result.values;
    });
  }
}

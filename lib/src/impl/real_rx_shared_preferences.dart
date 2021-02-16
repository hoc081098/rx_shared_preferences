import 'dart:async';

import 'package:rx_storage/rx_storage.dart';

import '../../rx_shared_preferences.dart';
import '../interface/rx_shared_preferences.dart';
import '../logger/logger.dart';

/// Default [RxSharedPreferences] implementation
class RealRxSharedPreferences
    extends RealRxStorage<String, void, SharedPreferencesLike>
    implements RxSharedPreferences {
  ///
  RealRxSharedPreferences(
    FutureOr<SharedPreferencesLike> prefsLikeOrFuture, [
    RxSharedPreferencesLogger? logger,
    void Function()? onDispose,
  ]) : super(prefsLikeOrFuture, logger, onDispose);

  @override
  Future<Map<String, Object?>> reload() async {
    final handler = (Object? _, Object? __) => null;

    final before =
        await useStorageWithHandlers((s) => s.readAll(), handler, handler);

    return useStorageWithHandlers(
      (s) => s.reload(),
      (value, s) {
        sendChange(_computeMap(before, value));
        log(ReloadSuccessEvent(value.toListOfKeyAndValues()));
      },
      (error, _) => log(ReloadFailureEvent(error)),
    );
  }

  static Map<String, Object?> _computeMap(
    Map<String, Object?> before,
    Map<String, Object?> after,
  ) {
    final deletedKeys = before.keys.toSet().difference(after.keys.toSet());
    return <String, Object?>{
      ...after,
      for (final k in deletedKeys) k: null,
    };
  }
}

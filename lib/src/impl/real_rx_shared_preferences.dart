import 'dart:async';

import 'package:rx_storage/rx_storage.dart';

import '../../rx_shared_preferences.dart';
import '../interface/rx_shared_preferences.dart';

/// Default [RxSharedPreferences] implementation
class RealRxSharedPreferences
    extends RealRxStorage<String, SharedPreferencesLike>
    implements RxSharedPreferences {
  final Logger _logger;

  ///
  RealRxSharedPreferences(
    FutureOr<SharedPreferencesLike> prefsLikeOrFuture, [
    Logger logger,
    void Function() onDispose,
  ])  : _logger = logger,
        super(prefsLikeOrFuture, logger, onDispose);

  @override
  Future<void> reload() async {
    await useStorage((s) => s.reload());
    sendChange(await readAll());
  }
}

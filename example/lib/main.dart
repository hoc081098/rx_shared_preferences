import 'package:example/home.dart';
import 'package:flutter/material.dart';
import 'package:rx_shared_preference/rx_shared_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  /// Singleton instance for app
  final rxPrefs = RxSharedPreferences(
    SharedPreferences.getInstance(),
    const DefaultLogger(),
  );
  runApp(
    RxPrefsProvider(
      rxPrefs: rxPrefs,
      child: MyApp(),
    ),
  );
}

/// Widget that efficiently provider [RxSharedPreferences] down the tree.
class RxPrefsProvider extends InheritedWidget {
  final RxSharedPreferences _rxPrefs;

  RxPrefsProvider({
    @required RxSharedPreferences rxPrefs,
    @required Widget child,
    Key key,
  })  : assert(rxPrefs != null),
        assert(child != null),
        this._rxPrefs = rxPrefs,
        super(key: key, child: child);

  static RxSharedPreferences of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(RxPrefsProvider)
            as RxPrefsProvider)
        ._rxPrefs;
  }

  @override
  bool updateShouldNotify(RxPrefsProvider oldWidget) =>
      oldWidget._rxPrefs != _rxPrefs;
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rx Shared Preference example',
      theme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}

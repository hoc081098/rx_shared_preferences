import 'package:flutter/material.dart';
import 'package:rx_shared_preference/rx_shared_preference.dart';

/// Widget that efficiently provider [RxSharedPreferences] down the tree.
class RxPrefsProvider extends StatefulWidget {
  final RxSharedPreferences rxPrefs;
  final Widget child;

  const RxPrefsProvider({
    Key key,
    @required this.rxPrefs,
    @required this.child,
  })  : assert(rxPrefs != null),
        assert(child != null),
        super(key: key);

  @override
  _RxPrefsProviderState createState() => _RxPrefsProviderState();

  static RxSharedPreferences of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_RxPrefsProviderInherited)
            as _RxPrefsProviderInherited)
        .rxPrefs;
  }
}

class _RxPrefsProviderState extends State<RxPrefsProvider> {
  @override
  Widget build(BuildContext context) {
    return _RxPrefsProviderInherited(
      child: widget.child,
      rxPrefs: widget.rxPrefs,
    );
  }

  @override
  void dispose() {
    widget.rxPrefs.dispose();
    super.dispose();
  }
}

class _RxPrefsProviderInherited extends InheritedWidget {
  final RxSharedPreferences rxPrefs;

  _RxPrefsProviderInherited({
    @required this.rxPrefs,
    @required Widget child,
    Key key,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_RxPrefsProviderInherited oldWidget) =>
      oldWidget.rxPrefs != rxPrefs;
}

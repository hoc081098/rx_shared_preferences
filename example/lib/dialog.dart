import 'package:example/home.dart';
import 'package:example/rx_prefs_provider.dart';
import 'package:flutter/material.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';

void showDialogAdd(BuildContext context) async {
  final string = await showDialog<String>(
    context: context,
    builder: (context) {
      String text;

      return AlertDialog(
        title: Text('Add a string'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          onChanged: (val) => text = val,
          onSubmitted: (val) => Navigator.of(context).pop(val),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          FlatButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(text),
          ),
        ],
      );
    },
  );
  if (string == null) {
    return;
  }

  final rxPrefs = context.rxPrefs;
  final currentList = await rxPrefs.getStringList(key);
  final newList = [...?currentList, string];
  final result = await rxPrefs.setStringList(key, newList);

  context.showSnackBar(
      result ? "Add '$string' successfully" : "Add '$string' not successfully");
}

void showDialogRemove(String needRemove, BuildContext context) async {
  final remove = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Remove this string'),
        actions: <Widget>[
          FlatButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          FlatButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );
  if (remove != true) {
    return;
  }

  final rxPrefs = context.rxPrefs;
  final currentList = await rxPrefs.getStringList(key) ?? <String>[];
  final newList =
      currentList.where((s) => s != needRemove).toList(growable: false);
  final result = await rxPrefs.setStringList(key, newList);

  context.showSnackBar(
    result
        ? "Remove '$needRemove' successfully"
        : "Remove '$needRemove' not successfully",
  );
}

extension on BuildContext {
  RxSharedPreferences get rxPrefs => RxPrefsProvider.of(this);

  void showSnackBar(String message) {
    Scaffold.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

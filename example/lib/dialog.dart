import 'package:example/home.dart';
import 'package:example/rx_prefs_provider.dart';
import 'package:flutter/material.dart';

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

  final rxPrefs = RxPrefsProvider.of(context);
  final currentList = await rxPrefs.getStringList(key) ?? <String>[];
  final result = await rxPrefs.setStringList(key, [...currentList, string]);

  Scaffold.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result
            ? "Add '$string' successfully"
            : "Add '$string' not successfully",
      ),
      duration: const Duration(seconds: 2),
    ),
  );
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

  final rxPrefs = RxPrefsProvider.of(context);
  final currentList = await rxPrefs.getStringList(key) ?? <String>[];
  final result = await rxPrefs.setStringList(
    key,
    currentList.where((s) => s != needRemove).toList(growable: false),
  );

  Scaffold.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result
            ? "Remove '$needRemove' successfully"
            : "Remove '$needRemove' not successfully",
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

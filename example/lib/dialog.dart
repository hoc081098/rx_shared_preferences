import 'package:example/home.dart';
import 'package:flutter/material.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';

extension DialogExtensions on BuildContext {
  void showDialogAdd() async {
    final string = await showDialog<String>(
      context: this,
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

    final currentList = await rxPrefs.getStringList(key);
    if (currentList?.contains(string) ?? false) {
      return showSnackBar('Duplicated!');
    }

    final newList = [...?currentList, string];
    final result = await rxPrefs.setStringList(key, newList);

    showSnackBar(result
        ? "Add '$string' successfully"
        : "Add '$string' not successfully");
  }

  void showDialogRemove(String needRemove) async {
    final remove = await showDialog<bool>(
      context: this,
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

    final currentList = await rxPrefs.getStringList(key) ?? <String>[];
    final newList = [
      for (final s in currentList)
        if (s != needRemove) s
    ];
    final result = await rxPrefs.setStringList(key, newList);

    showSnackBar(
      result
          ? "Remove '$needRemove' successfully"
          : "Remove '$needRemove' not successfully",
    );
  }
}

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
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
            TextButton(
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
    try {
      await rxPrefs.setStringList(key, newList);
      showSnackBar("Add '$string' successfully");
    } catch (_) {
      showSnackBar("Add '$string' not successfully");
    }
  }

  void showDialogRemove(String needRemove) async {
    final remove = await showDialog<bool>(
      context: this,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove this string'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
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
    try {
      await rxPrefs.setStringList(key, newList);
      showSnackBar("Remove '$needRemove' successfully");
    } catch (_) {
      showSnackBar("Remove '$needRemove' not successfully");
    }
  }
}

import 'package:example/home.dart';
import 'package:flutter/material.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';

extension DialogExtensions on BuildContext {
  void showDialogAdd() async {
    final string = await showDialog<String>(
      context: this,
      builder: (context) {
        String? text;

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
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(text),
              child: Text('OK'),
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
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
    if (remove != true) {
      return;
    }

    try {
      await rxPrefs.executeUpdateStringList(
        key,
        (currentList) => [
          for (final s in currentList ?? const <String>[])
            if (s != needRemove) s
        ],
      );
      showSnackBar("Remove '$needRemove' successfully");
    } catch (_) {
      showSnackBar("Remove '$needRemove' not successfully");
    }
  }
}

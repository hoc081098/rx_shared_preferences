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
          title: const Text('Add a string'),
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
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(text),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (string == null) {
      return;
    }

    try {
      await rxPrefs.updateStringList(key, (currentList) {
        final list = currentList ?? const <String>[];
        if (list.contains(string)) {
          throw StateError('Duplicated $string!');
        }
        return [...list, string];
      });
      showSnackBar("Add '$string' successfully");
    } catch (e) {
      showSnackBar("Add '$string' not successfully: $e");
    }
  }

  void showDialogRemove(String needRemove) async {
    final remove = await showDialog<bool>(
      context: this,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove this string'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (remove != true) {
      return;
    }

    try {
      await rxPrefs.updateStringList(
        key,
        (currentList) => [
          for (final s in (currentList ?? const <String>[]))
            if (s != needRemove) s
        ],
      );
      showSnackBar("Remove '$needRemove' successfully");
    } catch (e) {
      showSnackBar("Remove '$needRemove' not successfully: $e");
    }
  }
}

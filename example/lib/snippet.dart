// ignore_for_file: avoid_print, prefer_function_declarations_over_variables

import 'dart:convert';

import 'package:rx_shared_preferences/rx_shared_preferences.dart';

// ignore_for_file: omit_local_variable_types, unused_local_variable

class User {
  final String id;
  final String username;

  User(this.id, this.username);

  factory User.fromJson(Map<String, dynamic> json) =>
      User(json['id'], json['username']);

  Map<String, dynamic> toJson() => {'id': id, 'username': username};
}

final toUserOrNull =
    (Object? s) => s == null ? null : User.fromJson(jsonDecode(s as String));
const idsKey = 'ids';
const userKey = 'user';

void main() async {
  // Get RxSharedPreferences instance.
  final rxPrefs = RxSharedPreferences.getAsyncInstance();

  // Select stream by key and observe
  rxPrefs
      .getStringListStream(idsKey)
      .map((ids) => ids ?? [])
      .listen((List<String> ids) => print('Ids: $ids'));
  rxPrefs
      .observe(userKey, toUserOrNull)
      .listen((User? user) => print('User: $user'));

  // Get/read, set/write
  final List<String>? currentIds = await rxPrefs.getStringList(idsKey);
  await rxPrefs
      .setStringList(idsKey, [...?currentIds, 'new id', 'and more...']);

  final User? currentUser = await rxPrefs.read<User>(userKey, toUserOrNull);
  await rxPrefs.write<User>(
    userKey,
    User('id', 'username'),
    (u) => u == null ? null : jsonEncode(u),
  );

  // Or read-modify-write style.
  await rxPrefs.updateStringList(
      idsKey, (currentIds) => [...?currentIds, 'new id']);
}

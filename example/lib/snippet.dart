// ignore_for_file: avoid_print, prefer_function_declarations_over_variables

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';

// ignore_for_file: omit_local_variable_types, unused_local_variable
// ignore_for_file: experimental_member_use

class User {
  final String id;
  final String username;

  User(this.id, this.username);

  factory User.fromJson(Map<String, dynamic> json) =>
      User(json['id'], json['username']);

  Map<String, dynamic> toJson() => {'id': id, 'username': username};
}

final toUserOrNull = (Object? s) =>
    s == null ? null : User.fromJson(jsonDecode(s as String));
const idsKey = 'ids';
const userKey = 'user';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Get RxSharedPreferences instance.
  final rxPrefs = RxSharedPreferences.getAsyncInstance();

  // Select stream by key and observe
  final idsSubscription = rxPrefs
      .getStringListStream(idsKey)
      .map((ids) => ids ?? [])
      .listen((List<String> ids) => print('Ids: $ids'));
  final userSubscription = rxPrefs
      .observe(userKey, toUserOrNull)
      .listen((User? user) => print('User: $user'));

  // Bulk streams decode every snapshot, including the initial read.
  final rawSubscription = rxPrefs
      .observeAll((_, raw) => raw)
      .listen((values) => print('Raw: $values'));
  final decodedSubscription = rxPrefs
      .observeAll((key, raw) => key == userKey ? toUserOrNull(raw) : raw)
      .listen((values) => print('Decoded: $values'));

  try {
    // Get/read, set/write
    final List<String>? currentIds = await rxPrefs.getStringList(idsKey);
    await rxPrefs.setStringList(idsKey, [
      ...?currentIds,
      'new id',
      'and more...',
    ]);

    final User? currentUser = await rxPrefs.read<User>(userKey, toUserOrNull);
    await rxPrefs.write<User>(
      userKey,
      User('id', 'username'),
      (u) => u == null ? null : jsonEncode(u),
    );

    // Or read-modify-write style.
    await rxPrefs.updateStringList(
      idsKey,
      (currentIds) => [...?currentIds, 'new id'],
    );

    // Read all entries with an identity or key-specific decoder.
    final raw = await rxPrefs.readAll((_, raw) => raw);
    final decoded = await rxPrefs.readAll(
      (key, raw) => key == userKey ? toUserOrNull(raw) : raw,
    );
    print('Raw: $raw');
    print('Decoded: $decoded');
  } finally {
    await idsSubscription.cancel();
    await userSubscription.cancel();
    await rawSubscription.cancel();
    await decodedSubscription.cancel();
    await rxPrefs.dispose();
  }
}

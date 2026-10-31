// ignore_for_file: avoid_print, prefer_function_declarations_over_variables
// ignore_for_file: omit_local_variable_types, unused_local_variable
// ignore_for_file: experimental_member_use

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

@immutable
class User {
  final String id;
  final String username;

  const User(this.id, this.username);

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
  final subscriptions = CompositeSubscription();

  // Select stream by key and observe
  rxPrefs
      .getStringListStream(idsKey)
      .map((ids) => ids ?? [])
      .listen((List<String> ids) => print('Ids: $ids'))
      .addTo(subscriptions);
  rxPrefs
      .observe(userKey, toUserOrNull)
      .listen((User? user) => print('User: $user'))
      .addTo(subscriptions);

  // Bulk streams decode every snapshot, including the initial read.
  rxPrefs
      .observeAll((_, raw) => raw)
      .listen((values) => print('Raw: $values'))
      .addTo(subscriptions);
  rxPrefs
      .observeAll((key, raw) => key == userKey ? toUserOrNull(raw) : raw)
      .listen((values) => print('Decoded: $values'))
      .addTo(subscriptions);

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
    await subscriptions.dispose();
    await rxPrefs.dispose();
  }
}

import 'dart:convert';

class User {
  final String id;
  final String name;
  final int age;

  const User(this.id, this.name, this.age);

  factory User.fromJson(Map<String, dynamic> json) =>
      User(json['id'], json['name'], json['age']);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  @override
  String toString() => 'User{id: $id, name: $name, age: $age}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ age.hashCode;
}

const user1 = User('1', 'Name 1', 20);
const user2 = User('2', 'Name 2', 30);

User? userFromString(Object? s) =>
    s == null ? null : User.fromJson(jsonDecode(s as String));

Future<User?> userFromStringFuture(Object? s) async =>
    s == null ? null : User.fromJson(jsonDecode(s as String));

String? userToString(User? u) => u == null ? null : jsonEncode(u);

Future<String?> userToStringFuture(User? u) async =>
    u == null ? null : jsonEncode(u);

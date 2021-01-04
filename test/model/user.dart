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

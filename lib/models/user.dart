class User {
  final String name;
  final String username;
  final int age;
  final String country;
  final String password;

  User({
    required this.name,
    required this.username,
    required this.age,
    required this.country,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'age': age,
      'country': country,
      'password': password,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      username: json['username'],
      age: json['age'],
      country: json['country'],
      password: json['password'],
    );
  }

  User copyWith({
    String? name,
    String? username,
    int? age,
    String? country,
    String? password,
  }) {
    return User(
      name: name ?? this.name,
      username: username ?? this.username,
      age: age ?? this.age,
      country: country ?? this.country,
      password: password ?? this.password,
    );
  }
}

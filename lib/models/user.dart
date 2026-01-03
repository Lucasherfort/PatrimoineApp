class User {
  final int id;
  final String username;
  final String passwordHash;

  User({
    required this.id,
    required this.username,
    required this.passwordHash,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      passwordHash: json['passwordHash'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'passwordHash': passwordHash,
  };
}
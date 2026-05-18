class UserModel {

  final String username;
  final String email;
  final int role;

  UserModel({
    required this.username,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {

    return UserModel(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {

    return {
      'username': username,
      'email': email,
      'role': role,
    };
  }
}
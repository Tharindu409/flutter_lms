class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // STUDENT, INSTRUCTOR or ADMIN
  final String? profileImageUrl;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString().toUpperCase(),
      profileImageUrl: json['profileImageUrl']?.toString(),
    );
  }

    UserModel withRole(String newRole) {
    return UserModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      role: newRole,
      profileImageUrl: profileImageUrl,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

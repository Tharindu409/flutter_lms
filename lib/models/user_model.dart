class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // STUDENT, INSTRUCTOR or ADMIN
  final String? bio;
  final String? profileImageUrl;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.bio,
    this.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString().toUpperCase(),
      bio: json['bio']?.toString(),
      profileImageUrl: json['profileImageUrl']?.toString(),
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    final value = '$first$last'.toUpperCase();
    return value.isEmpty ? '?' : value;
  }

  bool get hasProfileImage =>
      profileImageUrl != null && profileImageUrl!.isNotEmpty;

  UserModel withRole(String newRole) {
    return UserModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      role: newRole,
      bio: bio,
      profileImageUrl: profileImageUrl,
    );
  }
}
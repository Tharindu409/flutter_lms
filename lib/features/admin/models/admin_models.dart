import 'package:flutter_lms/utils/json_utils.dart';

class AdminDashboardSummary {
  const AdminDashboardSummary({
    this.totalStudents,
    this.totalInstructors,
    this.activeUsers,
    this.publishedCourses,
    this.nonCancelledEnrollments,
    this.completedEnrollments,
  });

  final int? totalStudents;
  final int? totalInstructors;
  final int? activeUsers;
  final int? publishedCourses;
  final int? nonCancelledEnrollments;
  final int? completedEnrollments;

  static const _keys = (
    totalStudents: 'totalStudents',
    totalInstructors: 'totalInstructors',
    activeUsers: 'activeUsers',
    publishedCourses: 'publishedCourses',
    nonCancelledEnrollments: 'nonCancelledEnrollments',
    completedEnrollments: 'completedEnrollments',
  );

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json, const ['dashboard', 'summary']);
    int? number(String key) => _nullableInt(map[key]);
    return AdminDashboardSummary(
      totalStudents: number(_keys.totalStudents),
      totalInstructors: number(_keys.totalInstructors),
      activeUsers: number(_keys.activeUsers),
      publishedCourses: number(_keys.publishedCourses),
      nonCancelledEnrollments: number(_keys.nonCancelledEnrollments),
      completedEnrollments: number(_keys.completedEnrollments),
    );
  }
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.status,
    this.profileImageUrl,
    this.createdAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String status;
  final String? profileImageUrl;
  final DateTime? createdAt;
  String get fullName => '$firstName $lastName'.trim();

  static const _keys = (
    id: 'id',
    alternateId: '_id',
    firstName: 'firstName',
    lastName: 'lastName',
    email: 'email',
    role: 'role',
    status: 'status',
    profileImageUrl: 'profileImageUrl',
    createdAt: 'createdAt',
  );

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: _string(json[_keys.id] ?? json[_keys.alternateId]),
    firstName: _string(json[_keys.firstName]),
    lastName: _string(json[_keys.lastName]),
    email: _string(json[_keys.email]),
    role: _string(json[_keys.role]).toUpperCase(),
    status: _string(json[_keys.status]).toUpperCase(),
    profileImageUrl: _nullableString(json[_keys.profileImageUrl]),
    createdAt: DateTime.tryParse(_string(json[_keys.createdAt])),
  );

  AdminUser withStatus(String value) => AdminUser(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    role: role,
    status: value,
    profileImageUrl: profileImageUrl,
    createdAt: createdAt,
  );
}

class AdminCategory {
  const AdminCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.slug,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final String slug;
  final bool isActive;

  static const _keys = (
    id: 'id',
    alternateId: '_id',
    name: 'name',
    description: 'description',
    slug: 'slug',
    isActive: 'isActive',
  );

  factory AdminCategory.fromJson(Map<String, dynamic> json) => AdminCategory(
    id: _string(json[_keys.id] ?? json[_keys.alternateId]),
    name: _string(json[_keys.name]),
    description: _string(json[_keys.description]),
    slug: _string(json[_keys.slug]),
    isActive: json[_keys.isActive] == true,
  );

  AdminCategory withActive(bool value) => AdminCategory(
    id: id,
    name: name,
    description: description,
    slug: slug,
    isActive: value,
  );
}

class AdminCourse {
  const AdminCourse({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.status,
    required this.level,
    required this.language,
    required this.categoryId,
    required this.instructor,
    this.averageRating,
    this.reviewCount,
    this.enrollmentCount,
    this.thumbnailUrl,
  });

  final String id;
  final String title;
  final String shortDescription;
  final String status;
  final String level;
  final String language;
  final String categoryId;
  final AdminPersonSummary? instructor;
  final double? averageRating;
  final int? reviewCount;
  final int? enrollmentCount;
  final String? thumbnailUrl;

  static const _keys = (
    id: 'id',
    alternateId: '_id',
    title: 'title',
    shortDescription: 'shortDescription',
    status: 'status',
    level: 'level',
    language: 'language',
    categoryId: 'categoryId',
    instructor: 'instructor',
    averageRating: 'averageRating',
    reviewCount: 'reviewCount',
    enrollmentCount: 'enrollmentCount',
    thumbnailUrl: 'thumbnailUrl',
    thumbnail: 'thumbnail',
  );

  factory AdminCourse.fromJson(Map<String, dynamic> json) => AdminCourse(
    id: _string(json[_keys.id] ?? json[_keys.alternateId]),
    title: _string(json[_keys.title]),
    shortDescription: _string(json[_keys.shortDescription]),
    status: _string(json[_keys.status]).toUpperCase(),
    level: _string(json[_keys.level]),
    language: _string(json[_keys.language]),
    categoryId: _referenceId(json[_keys.categoryId]),
    instructor: _person(json[_keys.instructor]),
    averageRating: _nullableDouble(json[_keys.averageRating]),
    reviewCount: _nullableInt(json[_keys.reviewCount]),
    enrollmentCount: _nullableInt(json[_keys.enrollmentCount]),
    thumbnailUrl: _thumbnailUrl(
      json[_keys.thumbnailUrl] ?? json[_keys.thumbnail],
    ),
  );

  AdminCourse withStatus(String value) => AdminCourse(
    id: id,
    title: title,
    shortDescription: shortDescription,
    status: value,
    level: level,
    language: language,
    categoryId: categoryId,
    instructor: instructor,
    averageRating: averageRating,
    reviewCount: reviewCount,
    enrollmentCount: enrollmentCount,
    thumbnailUrl: thumbnailUrl,
  );
}

class AdminPersonSummary {
  const AdminPersonSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  String get fullName => '$firstName $lastName'.trim();

  static const _keys = (
    id: 'id',
    alternateId: '_id',
    firstName: 'firstName',
    lastName: 'lastName',
    email: 'email',
  );

  factory AdminPersonSummary.fromJson(Map<String, dynamic> json) =>
      AdminPersonSummary(
        id: _string(json[_keys.id] ?? json[_keys.alternateId]),
        firstName: _string(json[_keys.firstName]),
        lastName: _string(json[_keys.lastName]),
        email: _string(json[_keys.email]),
      );
}

class AdminEnrollment {
  const AdminEnrollment({
    required this.id,
    required this.status,
    required this.progressPercentage,
    required this.student,
    required this.course,
    this.enrolledAt,
  });

  final String id;
  final String status;
  final double? progressPercentage;
  final AdminPersonSummary? student;
  final AdminCourseSummary? course;
  final DateTime? enrolledAt;

  static const _keys = (
    id: 'id',
    alternateId: '_id',
    status: 'status',
    progressPercentage: 'progressPercentage',
    student: 'student',
    course: 'course',
    enrolledAt: 'enrolledAt',
  );

  factory AdminEnrollment.fromJson(Map<String, dynamic> json) =>
      AdminEnrollment(
        id: _string(json[_keys.id] ?? json[_keys.alternateId]),
        status: _string(json[_keys.status]).toUpperCase(),
        progressPercentage: _nullableDouble(json[_keys.progressPercentage]),
        student: _person(json[_keys.student]),
        course: _courseSummary(json[_keys.course]),
        enrolledAt: DateTime.tryParse(_string(json[_keys.enrolledAt])),
      );
}

class AdminCourseSummary {
  const AdminCourseSummary({required this.id, required this.title});
  final String id;
  final String title;

  static const _keys = (id: 'id', alternateId: '_id', title: 'title');

  factory AdminCourseSummary.fromJson(Map<String, dynamic> json) =>
      AdminCourseSummary(
        id: _string(json[_keys.id] ?? json[_keys.alternateId]),
        title: _string(json[_keys.title]),
      );
}

class AdminReview {
  const AdminReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.isVisible,
    required this.student,
  });

  final String id;
  final double rating;
  final String comment;
  final bool isVisible;
  final AdminPersonSummary? student;

  static const _keys = (
    id: 'id',
    alternateId: '_id',
    rating: 'rating',
    comment: 'comment',
    isVisible: 'isVisible',
    student: 'student',
  );

  factory AdminReview.fromJson(Map<String, dynamic> json) => AdminReview(
    id: _string(json[_keys.id] ?? json[_keys.alternateId]),
    rating: _double(json[_keys.rating]),
    comment: _string(json[_keys.comment]),
    isVisible: json[_keys.isVisible] != false,
    student: _person(json[_keys.student]),
  );

  AdminReview withVisibility(bool value) => AdminReview(
    id: id,
    rating: rating,
    comment: comment,
    isVisible: value,
    student: student,
  );
}

Map<String, dynamic> _unwrap(
  Map<String, dynamic> json,
  List<String> envelopeKeys,
) {
  var current = json;
  for (var depth = 0; depth < 3; depth++) {
    Map<String, dynamic>? nested;
    for (final key in envelopeKeys) {
      final value = JsonUtils.asMap(current[key]);
      if (value != null) {
        nested = value;
        break;
      }
    }
    if (nested == null) break;
    current = nested;
  }
  return current;
}

AdminPersonSummary? _person(dynamic value) {
  final map = JsonUtils.asMap(value);
  return map == null ? null : AdminPersonSummary.fromJson(map);
}

AdminCourseSummary? _courseSummary(dynamic value) {
  final map = JsonUtils.asMap(value);
  return map == null ? null : AdminCourseSummary.fromJson(map);
}

String _referenceId(dynamic value) {
  if (value is Map) return _string(value['id'] ?? value['_id']);
  return _string(value);
}

String _string(dynamic value) => value?.toString() ?? '';
String? _nullableString(dynamic value) => value?.toString();
int? _nullableInt(dynamic value) =>
    value == null ? null : int.tryParse(value.toString());
double _double(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
double? _nullableDouble(dynamic value) =>
    value == null ? null : double.tryParse(value.toString());

String? _thumbnailUrl(dynamic value) {
  if (value is String && value.isNotEmpty) return value;
  final map = JsonUtils.asMap(value);
  return _nullableString(map?['url'] ?? map?['secure_url']);
}

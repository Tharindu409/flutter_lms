import 'package:flutter_lms/models/course_category.dart';
import 'package:flutter_lms/utils/json_utils.dart';

class CourseInstructor {
  final String id;
  final String firstName;
  final String lastName;
  final String? headline;
  final String? profileImageUrl;

  const CourseInstructor({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.headline,
    this.profileImageUrl,
  });

  factory CourseInstructor.fromJson(Map<String, dynamic> json) {
    return CourseInstructor(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      headline: json['headline']?.toString(),
      profileImageUrl: json['profileImageUrl']?.toString(),
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

class Course {
  final String id;
  final String title;
  final String shortDescription;
  final String description;
  final String level;
  final String language;
  final String? thumbnailUrl;
  final num price;
  final double averageRating;
  final int reviewCount;
  final int enrollmentCount;
  final String status;
  final CourseCategory? category;
  final CourseInstructor? instructor;
  final List<String> requirements;
  final List<String> learningOutcomes;
  final List<String> targetAudience;

  const Course({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.description,
    required this.level,
    required this.language,
    this.thumbnailUrl,
    required this.price,
    required this.averageRating,
    required this.reviewCount,
    required this.enrollmentCount,
    required this.status,
    this.category,
    this.instructor,
    this.requirements = const [],
    this.learningOutcomes = const [],
    this.targetAudience = const [],
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    // The backend may send the category/instructor as an object or only an id.
    final categoryJson = _firstMap(json, ['category', 'categoryId']);
    final instructorJson = _firstMap(json, ['instructor', 'instructorId']);

    return Course(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      shortDescription: (json['shortDescription'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      language: (json['language'] ?? '').toString(),
      thumbnailUrl: _urlOf(json['thumbnailUrl'] ?? json['thumbnail']),
      price: num.tryParse(json['price']?.toString() ?? '') ?? 0,
      averageRating:
          double.tryParse(json['averageRating']?.toString() ?? '') ?? 0,
      reviewCount: int.tryParse(json['reviewCount']?.toString() ?? '') ?? 0,
      enrollmentCount:
          int.tryParse(json['enrollmentCount']?.toString() ?? '') ?? 0,
      status: (json['status'] ?? '').toString(),
      category: categoryJson == null
          ? null
          : CourseCategory.fromJson(categoryJson),
      instructor: instructorJson == null
          ? null
          : CourseInstructor.fromJson(instructorJson),
      requirements: JsonUtils.stringList(json['requirements']),
      learningOutcomes: JsonUtils.stringList(json['learningOutcomes']),
      targetAudience: JsonUtils.stringList(json['targetAudience']),
    );
  }

  bool get isFree => price == 0;

  String get levelLabel {
    switch (level) {
      case 'BEGINNER':
        return 'Beginner';
      case 'INTERMEDIATE':
        return 'Intermediate';
      case 'ADVANCED':
        return 'Advanced';
      case 'ALL_LEVELS':
        return 'All levels';
      default:
        return level;
    }
  }

  static Map<String, dynamic>? _firstMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) return value;
    }
    return null;
  }

  static String? _urlOf(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    if (value is Map) {
      final url = (value['url'] ?? value['secure_url'])?.toString();
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }
}

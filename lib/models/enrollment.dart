import 'package:flutter_lms/models/course.dart';

class Enrollment {
  final String id;
  final String courseId;
  final String? status; // ACTIVE, COMPLETED or CANCELLED
  final double? progressPercentage; // backend value, if supplied
  final Course? course;
  final DateTime? enrolledAt;

  const Enrollment({
    required this.id,
    required this.courseId,
    this.status,
    this.progressPercentage,
    this.course,
    this.enrolledAt,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    // The backend may send the course as a populated object or only an id.
    Map<String, dynamic>? courseJson;
    for (final key in const ['course', 'courseId']) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        courseJson = value;
        break;
      }
    }

    final courseId = courseJson != null
        ? (courseJson['id'] ?? courseJson['_id'] ?? '').toString()
        : (json['courseId'] ?? json['course'] ?? '').toString();

    return Enrollment(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      courseId: courseId,
      status: json['status']?.toString().toUpperCase(),
      progressPercentage: double.tryParse(
        json['progressPercentage']?.toString() ?? '',
      ),
      course: courseJson == null ? null : Course.fromJson(courseJson),
      enrolledAt: DateTime.tryParse(
        (json['enrolledAt'] ?? json['createdAt'] ?? '').toString(),
      ),
    );
  }

  bool get isActive => status == 'ACTIVE';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';

  /// Active or completed enrollments give access to the course content.
  bool get hasAccess => isActive || isCompleted;
}

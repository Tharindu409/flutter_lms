import 'package:flutter_lms/utils/json_utils.dart';

/// Progress of one course for the logged-in student, as calculated by the backend.
class CourseProgress {
  final String enrollmentStatus;
  final double progressPercentage;
  final int completedLessons;
  final int totalLessons;
  final Map<String, String> lessonStatuses; // lessonId -> status

  const CourseProgress({
    required this.enrollmentStatus,
    required this.progressPercentage,
    required this.completedLessons,
    required this.totalLessons,
    required this.lessonStatuses,
  });

  static const notStarted = 'NOT_STARTED';
  static const inProgress = 'IN_PROGRESS';
  static const completed = 'COMPLETED';

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    final enrollment =
        JsonUtils.asMap(json['enrollment']) ?? const <String, dynamic>{};

    final percent =
        double.tryParse(
          (json['progressPercentage'] ?? enrollment['progressPercentage'] ?? 0)
              .toString(),
        ) ??
        0;

    final status =
        (json['enrollmentStatus'] ??
                enrollment['status'] ??
                json['status'] ??
                '')
            .toString();

    final statuses = <String, String>{};
    final rawLessons = json['lessons'] ?? json['progress'];
    if (rawLessons is List) {
      for (final item in rawLessons) {
        final map = JsonUtils.asMap(item);
        if (map == null) continue;

        final lesson = JsonUtils.asMap(map['lesson']);
        final id =
            (lesson?['id'] ??
                    lesson?['_id'] ??
                    map['lessonId'] ??
                    map['id'] ??
                    map['_id'] ??
                    '')
                .toString();
        if (id.isEmpty) continue;

        statuses[id] = (map['progressStatus'] ?? map['status'] ?? notStarted)
            .toString();
      }
    }

    final completedCount = statuses.values.where((s) => s == completed).length;

    return CourseProgress(
      enrollmentStatus: status,
      progressPercentage: percent,
      completedLessons:
          int.tryParse(json['completedLessons']?.toString() ?? '') ??
          completedCount,
      totalLessons:
          int.tryParse(json['totalLessons']?.toString() ?? '') ??
          statuses.length,
      lessonStatuses: statuses,
    );
  }

  String statusOf(String lessonId) => lessonStatuses[lessonId] ?? notStarted;
}

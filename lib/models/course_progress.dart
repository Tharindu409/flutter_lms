import 'package:flutter_lms/utils/json_utils.dart';

/// Progress of one course for the logged-in student, as calculated by the backend.
class CourseProgress {
  final String? enrollmentStatus;
  final double? progressPercentage;
  final int? completedLessons;
  final int? totalLessons;
  final Map<String, String?> lessonStatuses;

  const CourseProgress({
    this.enrollmentStatus,
    this.progressPercentage,
    this.completedLessons,
    this.totalLessons,
    this.lessonStatuses = const {},
  });

  static const notStarted = 'NOT_STARTED';
  static const inProgress = 'IN_PROGRESS';
  static const completed = 'COMPLETED';

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    final enrollment =
        JsonUtils.asMap(json['enrollment']) ?? const <String, dynamic>{};
    final percent = double.tryParse(
      (json['progressPercentage'] ?? enrollment['progressPercentage'])
              ?.toString() ??
          '',
    );
    final rawStatus =
        json['enrollmentStatus'] ?? enrollment['status'] ?? json['status'];

    final statuses = <String, String?>{};
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
        final rawLessonStatus = map['progressStatus'] ?? map['status'];
        if (id.isEmpty || rawLessonStatus == null) continue;
        statuses[id] = rawLessonStatus.toString();
      }
    }

    return CourseProgress(
      enrollmentStatus: rawStatus?.toString(),
      progressPercentage: percent,
      completedLessons: int.tryParse(
        json['completedLessons']?.toString() ?? '',
      ),
      totalLessons: int.tryParse(json['totalLessons']?.toString() ?? ''),
      lessonStatuses: statuses,
    );
  }

  String? statusOf(String lessonId) => lessonStatuses[lessonId];
}

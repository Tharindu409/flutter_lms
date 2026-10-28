class InstructorSummary {
  final int totalCourses;
  final int publishedCourses;
  final int draftCourses;
  final int archivedCourses;
  final int totalEnrollments;
  final int pendingSubmissions;
  final double averageRating;

  const InstructorSummary({
    required this.totalCourses,
    required this.publishedCourses,
    required this.draftCourses,
    required this.archivedCourses,
    required this.totalEnrollments,
    required this.pendingSubmissions,
    required this.averageRating,
  });

  /// [json] is the "data" part of GET /api/v1/dashboard/instructor.
  /// The numbers sit under data.dashboard; _find also searches nested objects.
  factory InstructorSummary.fromJson(Map<String, dynamic> json) {
    int count(List<String> keys) => _find(json, keys)?.toInt() ?? 0;

    final published = count(['publishedCourses']);
    final draft = count(['draftCourses']);
    final archived = count(['archivedCourses']);

    return InstructorSummary(
      totalCourses:
          _find(json, ['totalCourses'])?.toInt() ??
          published + draft + archived,
      publishedCourses: published,
      draftCourses: draft,
      archivedCourses: archived,
      totalEnrollments: count([
        'totalEnrollments',
        'activeEnrollments',
        'totalActiveEnrollments',
      ]),
      pendingSubmissions: count(['pendingSubmissions']),
      averageRating:
          _find(json, ['averageCourseRating', 'averageRating'])?.toDouble() ??
          0,
    );
  }

  static num? _find(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = num.tryParse(json[key]?.toString() ?? '');
      if (value != null) return value;
    }
    for (final value in json.values) {
      if (value is Map<String, dynamic>) {
        final nested = _find(value, keys);
        if (nested != null) return nested;
      }
    }
    return null;
  }
}

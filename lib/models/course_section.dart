class CourseSection {
  final String id;
  final String title;
  final String description;
  final int order;
  final int lessonCount;
  final bool isPublished;

  const CourseSection({
    required this.id,
    required this.title,
    this.description = '',
    this.order = 0,
    this.lessonCount = 0,
    this.isPublished = true,
  });

  factory CourseSection.fromJson(Map<String, dynamic> json) {
    return CourseSection(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      order: _toInt(json['order']) ?? 0,
      lessonCount: _lessonCount(json),
      isPublished: json['isPublished'] is bool
          ? json['isPublished'] as bool
          : true,
    );
  }

  static int _lessonCount(Map<String, dynamic> json) {
    for (final key in const [
      'lessonCount',
      'lessonsCount',
      'publishedLessonCount',
      'publishedLessonsCount',
      'totalLessons',
    ]) {
      final value = _toInt(json[key]);
      if (value != null) return value;
    }
    final lessons = json['lessons'];
    return lessons is List ? lessons.length : 0;
  }

  static int? _toInt(dynamic value) => int.tryParse(value?.toString() ?? '');
}

class Assignment {
  const Assignment({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.maximumMarks,
    this.status,
    this.courseId,
    this.courseTitle,
    this.attachmentUrl,
    this.attachmentName,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final num? maximumMarks;
  final String? status;
  final String? courseId;
  final String? courseTitle;
  final String? attachmentUrl;
  final String? attachmentName;

  factory Assignment.fromJson(Map<String, dynamic> json) {
    final attachment = json['attachment'] is Map
        ? json['attachment'] as Map
        : const <Object?, Object?>{};
    final rawStatus =
        json['submissionStatus'] ??
        json['status'] ??
        (json['submission'] is Map
            ? (json['submission'] as Map)['status']
            : null);
    final course = json['course'] is Map ? json['course'] as Map : null;
    return Assignment(
      id: (json['id'] ?? json['_id'] ?? json['assignmentId'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? 'Assignment').toString(),
      description: _nullableString(json['description']),
      dueDate: DateTime.tryParse(
        (json['dueDate'] ?? json['dueAt'] ?? '').toString(),
      ),
      maximumMarks: num.tryParse(
        (json['maximumMarks'] ?? json['maxMarks'] ?? '').toString(),
      ),
      status: _nullableString(rawStatus)?.toUpperCase(),
      courseId: _nullableString(
        json['courseId'] ?? course?['id'] ?? course?['_id'],
      ),
      attachmentUrl: _nullableString(
        json['attachmentUrl'] ?? attachment['url'] ?? attachment['fileUrl'],
      ),
      attachmentName: _nullableString(
        json['attachmentName'] ??
            attachment['originalName'] ??
            attachment['filename'] ??
            attachment['name'],
      ),
    );
  }

  Assignment forCourse(String title) => Assignment(
    id: id,
    title: this.title,
    description: description,
    dueDate: dueDate,
    maximumMarks: maximumMarks,
    status: status,
    courseId: courseId,
    courseTitle: title,
    attachmentUrl: attachmentUrl,
    attachmentName: attachmentName,
  );

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

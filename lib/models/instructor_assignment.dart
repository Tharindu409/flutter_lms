class InstructorAssignment {
  const InstructorAssignment({
    required this.id,
    required this.title,
    this.description,
    this.instructions,
    this.dueDate,
    this.maximumMarks,
    this.sectionId,
    this.isPublished,
    this.attachmentUrl,
    this.attachmentName,
  });

  final String id;
  final String title;
  final String? description;
  final String? instructions;
  final DateTime? dueDate;
  final num? maximumMarks;
  final String? sectionId;
  final bool? isPublished;
  final String? attachmentUrl;
  final String? attachmentName;

  factory InstructorAssignment.fromJson(Map<String, dynamic> json) {
    final attachment = json['attachment'] is Map
        ? json['attachment'] as Map
        : const <Object?, Object?>{};
    final section = json['section'] is Map
        ? json['section'] as Map
        : const <Object?, Object?>{};
    final status = (json['status'] ?? '').toString().toUpperCase();
    return InstructorAssignment(
      id: (json['id'] ?? json['_id'] ?? json['assignmentId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: _nullable(json['description']),
      instructions: _nullable(json['instructions']),
      dueDate: DateTime.tryParse((json['dueDate'] ?? '').toString()),
      maximumMarks: num.tryParse(
        (json['maximumMarks'] ?? json['maxMarks'] ?? '').toString(),
      ),
      sectionId: _nullable(
        json['sectionId'] ?? section['id'] ?? section['_id'],
      ),
      isPublished: json['isPublished'] is bool
          ? json['isPublished'] as bool
          : status == 'PUBLISHED'
          ? true
          : status == 'DRAFT' || status == 'UNPUBLISHED'
          ? false
          : null,
      attachmentUrl: _nullable(
        json['attachmentUrl'] ?? attachment['url'] ?? attachment['fileUrl'],
      ),
      attachmentName: _nullable(
        json['attachmentName'] ??
            attachment['originalName'] ??
            attachment['filename'] ??
            attachment['name'],
      ),
    );
  }

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class InstructorSubmission {
  const InstructorSubmission({
    required this.id,
    required this.assignmentId,
    this.studentName,
    this.textAnswer,
    this.fileUrl,
    this.fileName,
    this.status,
    this.submittedAt,
    this.marksAwarded,
    this.feedback,
  });

  final String id;
  final String assignmentId;
  final String? studentName;
  final String? textAnswer;
  final String? fileUrl;
  final String? fileName;
  final String? status;
  final String? submittedAt;
  final num? marksAwarded;
  final String? feedback;

  factory InstructorSubmission.fromJson(Map<String, dynamic> json) {
    final grade = json['grade'] is Map
        ? json['grade'] as Map
        : const <Object?, Object?>{};
    final student = json['student'] ?? json['user'];
    final studentMap = student is Map ? student : const {};
    final file = json['file'] is Map
        ? json['file'] as Map
        : json['submissionFile'] is Map
        ? json['submissionFile'] as Map
        : json['attachment'] is Map
        ? json['attachment'] as Map
        : const <Object?, Object?>{};
    final assignment = json['assignment'] is Map
        ? json['assignment'] as Map
        : const <Object?, Object?>{};
    final first = studentMap['firstName']?.toString() ?? '';
    final last = studentMap['lastName']?.toString() ?? '';
    return InstructorSubmission(
      id: (json['id'] ?? json['_id'] ?? json['submissionId'] ?? '').toString(),
      assignmentId:
          (json['assignmentId'] ?? assignment['id'] ?? assignment['_id'] ?? '')
              .toString(),
      studentName: _nullable(
        json['studentName'] ??
            studentMap['fullName'] ??
            studentMap['name'] ??
            '$first $last'.trim(),
      ),
      textAnswer: _nullable(
        json['textAnswer'] ??
            json['answerText'] ??
            json['submissionText'] ??
            json['text'] ??
            json['answer'],
      ),
      fileUrl: _nullable(
        json['fileUrl'] ??
            json['attachmentUrl'] ??
            file['url'] ??
            file['fileUrl'],
      ),
      fileName: _nullable(
        json['fileName'] ??
            json['attachmentName'] ??
            file['originalName'] ??
            file['filename'] ??
            file['name'],
      ),
      status: _nullable(json['status']),
      submittedAt: _nullable(json['submittedAt'] ?? json['createdAt']),
      marksAwarded: num.tryParse(
        (json['marksAwarded'] ??
                json['score'] ??
                grade['marksAwarded'] ??
                grade['score'] ??
                '')
            .toString(),
      ),
      feedback: _nullable(json['feedback'] ?? grade['feedback']),
    );
  }

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class InstructorEnrollment {
  const InstructorEnrollment({
    required this.id,
    this.studentName,
    this.status,
    this.progressPercentage,
    this.enrolledAt,
  });

  final String id;
  final String? studentName;
  final String? status;
  final String? progressPercentage;
  final String? enrolledAt;

  factory InstructorEnrollment.fromJson(Map<String, dynamic> json) {
    final student = json['student'] ?? json['user'];
    final studentMap = student is Map ? student : const {};
    final first = studentMap['firstName']?.toString() ?? '';
    final last = studentMap['lastName']?.toString() ?? '';
    return InstructorEnrollment(
      id: (json['id'] ?? json['_id'] ?? json['enrollmentId'] ?? '').toString(),
      studentName: _nullable(json['studentName'] ?? '$first $last'.trim()),
      status: _nullable(json['status']),
      progressPercentage: json['progressPercentage']?.toString(),
      enrolledAt: _nullable(json['enrolledAt'] ?? json['createdAt']),
    );
  }

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

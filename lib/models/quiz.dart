class Quiz {
  const Quiz({
    required this.id,
    required this.title,
    this.description,
    this.passingScore,
    this.timeLimitMinutes,
    this.maxAttempts,
    this.sectionId,
    this.isPublished,
    this.questionCount,
    this.questions = const [],
  });

  final String id;
  final String title;
  final String? description;
  final num? passingScore;
  final int? timeLimitMinutes;
  final int? maxAttempts;
  final String? sectionId;
  final bool? isPublished;
  final int? questionCount;
  final List<QuizQuestion> questions;

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: (json['id'] ?? json['_id'] ?? json['quizId'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? 'Quiz').toString(),
      description: _nullableString(json['description']),
      passingScore: num.tryParse(
        (json['passingScore'] ?? json['passingScorePercentage'] ?? '')
            .toString(),
      ),
      timeLimitMinutes: int.tryParse(
        (json['timeLimitMinutes'] ?? json['timeLimit'] ?? '').toString(),
      ),
      maxAttempts: int.tryParse((json['maxAttempts'] ?? '').toString()),
      sectionId: _nullableId(json['sectionId'] ?? json['section']),
      isPublished: json['isPublished'] is bool
          ? json['isPublished'] as bool
          : _statusPublished(json['status']),
      questionCount:
          int.tryParse(
            (json['questionCount'] ?? json['questionsCount'] ?? '').toString(),
          ) ??
          (json['questions'] is List
              ? (json['questions'] as List).length
              : null),
      questions: json['questions'] is List
          ? (json['questions'] as List)
                .whereType<Map<String, dynamic>>()
                .map(QuizQuestion.fromJson)
                .toList()
          : const [],
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String? _nullableId(dynamic value) {
    if (value is Map) return (value['id'] ?? value['_id'])?.toString();
    return _nullableString(value);
  }

  static bool? _statusPublished(dynamic value) {
    switch (value?.toString().toUpperCase()) {
      case 'PUBLISHED':
        return true;
      case 'DRAFT':
      case 'UNPUBLISHED':
        return false;
      default:
        return null;
    }
  }
}

class QuizOption {
  const QuizOption({required this.id, required this.text});

  final String id;
  final String text;

  factory QuizOption.fromJson(dynamic value) {
    if (value is Map) {
      return QuizOption(
        id: (value['id'] ?? value['_id'] ?? '').toString(),
        text: (value['text'] ?? value['optionText'] ?? '').toString(),
      );
    }
    return QuizOption(id: '', text: value?.toString() ?? '');
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.correctOptionIds,
    required this.marks,
  });

  final String id;
  final String questionText;
  final String questionType;
  final List<QuizOption> options;
  final List<String> correctOptionIds;
  final num? marks;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final options = json['options'];
    final correct = json['correctOptionIds'];
    return QuizQuestion(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      questionText: (json['questionText'] ?? json['text'] ?? '').toString(),
      questionType: (json['questionType'] ?? '').toString().toUpperCase(),
      options: options is List
          ? options.map(QuizOption.fromJson).toList()
          : const [],
      correctOptionIds: correct is List
          ? correct.map((value) => value.toString()).toList()
          : const [],
      marks: num.tryParse((json['marks'] ?? '').toString()),
    );
  }
}

class QuizAttempt {
  const QuizAttempt({
    required this.id,
    this.studentName,
    this.attemptNumber,
    this.score,
    this.percentage,
    this.passed,
    this.result,
    this.submittedAt,
  });

  final String id;
  final String? studentName;
  final String? attemptNumber;
  final String? score;
  final String? percentage;
  final bool? passed;
  final String? result;
  final String? submittedAt;

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    final student = json['student'] ?? json['user'];
    final studentMap = student is Map ? student : const {};
    final firstName = studentMap['firstName']?.toString() ?? '';
    final lastName = studentMap['lastName']?.toString() ?? '';
    final name = (json['studentName'] ?? '$firstName $lastName')
        .toString()
        .trim();
    final submitted = json['submittedAt'] ?? json['completedAt'];
    return QuizAttempt(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      studentName: name.isEmpty ? null : name,
      attemptNumber: _asString(json['attemptNumber']),
      score: _asString(json['score'] ?? json['marksAwarded']),
      percentage: _asString(json['percentage']),
      passed: json['passed'] is bool
          ? json['passed'] as bool
          : json['isPassed'] is bool
          ? json['isPassed'] as bool
          : null,
      result: _asString(json['result'] ?? json['status']),
      submittedAt: _asString(submitted),
    );
  }

  static String? _asString(dynamic value) => value?.toString();
}

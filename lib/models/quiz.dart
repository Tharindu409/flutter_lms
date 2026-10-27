class Quiz {
  const Quiz({
    required this.id,
    required this.title,
    this.description,
    this.passingScore,
    this.timeLimitMinutes,
    this.maxAttempts,
  });

  final String id;
  final String title;
  final String? description;
  final num? passingScore;
  final int? timeLimitMinutes;
  final int? maxAttempts;

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
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

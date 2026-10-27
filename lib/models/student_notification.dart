class StudentNotification {
  const StudentNotification({
    this.id,
    this.title,
    this.message,
    this.type,
    this.isRead,
    this.createdAt,
  });

  final String? id;
  final String? title;
  final String? message;
  final String? type;
  final bool? isRead;
  final DateTime? createdAt;

  factory StudentNotification.fromJson(Map<String, dynamic> json) {
    final rawRead = json['isRead'] ?? json['read'];
    final isRead = rawRead is bool
        ? rawRead
        : rawRead is String
        ? rawRead.toLowerCase() == 'true'
        : null;
    return StudentNotification(
      id: _stringOrNull(json['id'] ?? json['_id'] ?? json['notificationId']),
      title: _stringOrNull(json['title']),
      message: _stringOrNull(
        json['message'] ?? json['body'] ?? json['description'],
      ),
      type: _stringOrNull(json['type']),
      isRead: isRead,
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'] ?? '').toString(),
      ),
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

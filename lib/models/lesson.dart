class Lesson {
  final String id;
  final String sectionId;
  final String title;
  final String description;
  final String lessonType; // TEXT, VIDEO or DOCUMENT
  final String? textContent;
  final String? videoUrl;
  final String? documentUrl;
  final String? documentName;
  final int durationMinutes;
  final bool isPreview;
  final bool isPublished;
  final int order;

  const Lesson({
    required this.id,
    required this.sectionId,
    required this.title,
    this.description = '',
    required this.lessonType,
    this.textContent,
    this.videoUrl,
    this.documentUrl,
    this.documentName,
    this.durationMinutes = 0,
    this.isPreview = false,
    this.isPublished = true,
    this.order = 0,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final document = json['document'];

    String? documentName =
        json['documentName']?.toString() ??
        json['originalFilename']?.toString();
    if (documentName == null && document is Map) {
      documentName =
          (document['originalName'] ??
                  document['originalFilename'] ??
                  document['filename'])
              ?.toString();
    }

    return Lesson(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      sectionId: _idOf(json['sectionId'] ?? json['section']),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      lessonType: (json['lessonType'] ?? '').toString().toUpperCase(),
      textContent: json['textContent']?.toString(),
      videoUrl: _urlOf(json['videoUrl'] ?? json['video']),
      documentUrl: _urlOf(
        json['documentUrl'] ?? json['document'] ?? json['resourceUrl'],
      ),
      documentName: documentName,
      durationMinutes:
          int.tryParse(json['durationMinutes']?.toString() ?? '') ?? 0,
      isPreview: json['isPreview'] == true,
      isPublished: json['isPublished'] is bool
          ? json['isPublished'] as bool
          : true,
      order: int.tryParse(json['order']?.toString() ?? '') ?? 0,
    );
  }

  bool get isText => lessonType == 'TEXT';
  bool get isVideo => lessonType == 'VIDEO';
  bool get isDocument => lessonType == 'DOCUMENT';

  String get durationLabel => durationMinutes > 0 ? '$durationMinutes min' : '';

  static String _idOf(dynamic value) {
    if (value is Map) return (value['id'] ?? value['_id'] ?? '').toString();
    return value?.toString() ?? '';
  }

  static String? _urlOf(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    if (value is Map) {
      final url = (value['url'] ?? value['secure_url'])?.toString();
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }
}

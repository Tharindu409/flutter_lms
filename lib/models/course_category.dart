class CourseCategory {
  final String id;
  final String name;
  final String description;
  final bool isActive;

  const CourseCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.isActive = true,
  });

  factory CourseCategory.fromJson(Map<String, dynamic> json) {
    return CourseCategory(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
    );
  }
}

class CourseStatus {
  const CourseStatus._();

  static const draft = 'DRAFT';
  static const published = 'PUBLISHED';
  static const archived = 'ARCHIVED';

  static const all = [draft, published, archived];

  static String label(String status) {
    switch (status) {
      case draft:
        return 'Draft';
      case published:
        return 'Published';
      case archived:
        return 'Archived';
      default:
        return status;
    }
  }
}
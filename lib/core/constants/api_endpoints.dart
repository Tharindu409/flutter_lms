class ApiEndpoints {
  const ApiEndpoints._();

  static const adminDashboard = '/api/v1/dashboard/admin';
  static const users = '/api/v1/users';
  static String user(String userId) => '/api/v1/users/$userId';
  static String userStatus(String userId) => '/api/v1/users/$userId/status';
  static const categories = '/api/v1/categories';
  static String category(String categoryId) => '/api/v1/categories/$categoryId';
  static String categoryStatus(String categoryId) =>
      '/api/v1/categories/$categoryId/status';
  static const adminCourses = '/api/v1/courses/admin/all';
  static String course(String courseId) => '/api/v1/courses/$courseId';
  static String archiveCourse(String courseId) =>
      '/api/v1/courses/$courseId/admin/archive';
  static const adminEnrollments = '/api/v1/enrollments/admin/all';
  static String courseReviews(String courseId) =>
      '/api/v1/courses/$courseId/reviews';
  static String reviewVisibility(String reviewId) =>
      '/api/v1/reviews/$reviewId/visibility';
}

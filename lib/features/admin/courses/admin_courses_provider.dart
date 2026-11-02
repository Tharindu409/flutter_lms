import 'package:flutter_lms/features/admin/core/admin_paged_provider.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/features/admin/courses/admin_courses_service.dart';

class AdminCoursesProvider extends AdminPagedProvider<AdminCourse> {
  AdminCoursesProvider(this.service)
    : super(
        (page, filters) => service.list(
          page: page,
          search: filters['search'] ?? '',
          status: filters['status'] ?? '',
          instructorId: filters['instructorId'] ?? '',
          categoryId: filters['categoryId'] ?? '',
        ),
      );

  final AdminCoursesService service;
  AdminCourse? selectedCourse;

  Future<void> applyCourseFilters({
    String search = '',
    String status = '',
    String instructorId = '',
    String categoryId = '',
  }) => super.applyFilters({
    'search': search,
    'status': status,
    'instructorId': instructorId,
    'categoryId': categoryId,
  });

  Future<AdminCourse> loadCourseDetails(AdminCourse course) async {
    if (course.status == 'PUBLISHED') {
      selectedCourse = await runAction(
        () => service.publishedDetails(course.id),
      );
    } else {
      selectedCourse = course;
    }
    notifySafely();
    return selectedCourse!;
  }

  Future<void> archiveCourse(AdminCourse course) async {
    final archived = await runAction(() => service.archive(course.id));
    replaceItem((item) => item.id == course.id, archived);
    if (selectedCourse?.id == course.id) selectedCourse = archived;
    notifySafely();
  }

  @override
  void reset() {
    selectedCourse = null;
    super.reset();
  }
}

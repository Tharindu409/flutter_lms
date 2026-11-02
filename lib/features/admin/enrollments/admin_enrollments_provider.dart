import 'package:flutter_lms/features/admin/core/admin_paged_provider.dart';
import 'package:flutter_lms/features/admin/enrollments/admin_enrollments_service.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';

class AdminEnrollmentsProvider extends AdminPagedProvider<AdminEnrollment> {
  AdminEnrollmentsProvider(this.service)
    : super(
        (page, filters) => service.list(
          page: page,
          status: filters['status'] ?? '',
          courseId: filters['courseId'] ?? '',
          studentId: filters['studentId'] ?? '',
        ),
      );

  final AdminEnrollmentsService service;
  AdminEnrollment? selectedEnrollment;

  Future<void> applyEnrollmentFilters({
    String status = '',
    String courseId = '',
    String studentId = '',
  }) => super.applyFilters({
    'status': status,
    'courseId': courseId,
    'studentId': studentId,
  });

  void selectEnrollment(AdminEnrollment? value) {
    selectedEnrollment = value;
    notifySafely();
  }

  @override
  void reset() {
    selectedEnrollment = null;
    super.reset();
  }
}

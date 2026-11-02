import 'package:flutter_lms/models/instructor_summary.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('route role guard', () {
    test('blocks students from instructor routes', () {
      expect(
        AppRoutes.isRoleAllowed(AppRoutes.instructorDashboard, 'STUDENT'),
        isFalse,
      );
      expect(
        AppRoutes.isRoleAllowed(AppRoutes.instructorCourses, 'STUDENT'),
        isFalse,
      );
    });

    test('blocks instructors from student routes', () {
      expect(AppRoutes.isRoleAllowed(AppRoutes.courses, 'INSTRUCTOR'), isFalse);
      expect(
        AppRoutes.isRoleAllowed(AppRoutes.assignmentDetail, 'INSTRUCTOR'),
        isFalse,
      );
    });

    test('blocks non-admin roles from admin routes', () {
      expect(AppRoutes.isRoleAllowed(AppRoutes.adminUsers, 'STUDENT'), isFalse);
      expect(
        AppRoutes.isRoleAllowed(AppRoutes.adminCourses, 'INSTRUCTOR'),
        isFalse,
      );
      expect(AppRoutes.isRoleAllowed(AppRoutes.adminUsers, 'ADMIN'), isTrue);
    });

    test('allows shared routes for every logged-in role', () {
      for (final role in ['STUDENT', 'INSTRUCTOR', 'ADMIN']) {
        expect(AppRoutes.isRoleAllowed(AppRoutes.profile, role), isTrue);
        expect(AppRoutes.isRoleAllowed(AppRoutes.notifications, role), isTrue);
      }
      expect(AppRoutes.isRoleAllowed(AppRoutes.profile, null), isFalse);
      expect(AppRoutes.isRoleAllowed(AppRoutes.notifications, null), isFalse);
    });
  });

  test('does not derive total courses when the backend omits it', () {
    final summary = InstructorSummary.fromJson({
      'publishedCourses': 3,
      'draftCourses': 2,
      'archivedCourses': 1,
    });

    expect(summary.totalCourses, isNull);
  });
}

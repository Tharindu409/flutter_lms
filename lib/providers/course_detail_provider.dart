import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/course.dart';
import 'package:flutter_lms/models/course_section.dart';
import 'package:flutter_lms/models/enrollment.dart';
import 'package:flutter_lms/services/course_service.dart';
import 'package:flutter_lms/services/enrollment_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class CourseDetailProvider extends ChangeNotifier {
  CourseDetailProvider(this._courseService, this._enrollmentService);

  final CourseService _courseService;
  final EnrollmentService _enrollmentService;

  Course? course;
  List<CourseSection> sections = const [];
  Enrollment? enrollment;

  bool isLoading = false;
  bool isEnrolling = false;
  String? errorMessage; // the course itself could not be loaded
  String? curriculumNotice; // the curriculum could not be shown

  String _courseId = '';

  /// Active or completed enrollment gives access to the lessons.
  bool get isEnrolled => enrollment?.hasAccess ?? false;

  Future<void> load(String courseId) async {
    _courseId = courseId;
    course = null;
    sections = const [];
    enrollment = null;
    errorMessage = null;
    curriculumNotice = null;
    isLoading = true;
    notifyListeners();

    try {
      final loaded = await _courseService.getCourse(courseId);
      if (courseId != _courseId) return;
      course = loaded;
    } on ApiException catch (error) {
      if (courseId != _courseId) return;
      errorMessage = error.message;
      isLoading = false;
      notifyListeners();
      return;
    }

    await _loadEnrollment(courseId);
    if (courseId != _courseId) return;
    await _loadSections(courseId);
    if (courseId != _courseId) return;

    isLoading = false;
    notifyListeners();
  }

  /// Looks for this course in the student's enrollments (a few pages at most).
  Future<void> _loadEnrollment(String courseId) async {
    try {
      var page = 1;
      while (page <= 10) {
        final result = await _enrollmentService.getMyEnrollments(
          page: page,
          limit: 20,
        );
        for (final item in result.items) {
          if (item.courseId == courseId) {
            if (courseId == _courseId) enrollment = item;
            return;
          }
        }
        if (!result.hasMore) break;
        page++;
      }
      if (courseId == _courseId) enrollment = null;
    } on ApiException {
      // The backend checks access again on every protected request.
      if (courseId == _courseId) enrollment = null;
    }
  }

  Future<void> _loadSections(String courseId) async {
    try {
      final loaded = await _courseService.getSections(courseId);
      if (courseId != _courseId) return;
      sections = loaded;
      curriculumNotice = null;
    } on ApiException catch (error) {
      if (courseId != _courseId) return;
      sections = const [];
      curriculumNotice = error.statusCode == 403
          ? 'Enroll in this course to see its curriculum.'
          : error.message;
    }
  }

  /// Returns null on success, or an error message to show.
  Future<String?> enroll() async {
    final id = _courseId;
    if (id.isEmpty) return 'The course is not loaded yet.';

    isEnrolling = true;
    notifyListeners();

    String? error;
    try {
      await _enrollmentService.enroll(id);
    } on ApiException catch (e) {
      error = e.message;
    }

    // Always sync with the backend (it may already be enrolled).
    await _loadEnrollment(id);
    if (id == _courseId && isEnrolled) await _loadSections(id);

    isEnrolling = false;
    notifyListeners();
    return error;
  }

  void reset() {
    _courseId = '';
    course = null;
    sections = const [];
    enrollment = null;
    isLoading = false;
    isEnrolling = false;
    errorMessage = null;
    curriculumNotice = null;
    notifyListeners();
  }
}

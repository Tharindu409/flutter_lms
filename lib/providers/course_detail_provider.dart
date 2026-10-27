import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/course.dart';
import 'package:flutter_lms/models/course_section.dart';
import 'package:flutter_lms/models/enrollment.dart';
import 'package:flutter_lms/services/course_service.dart';
import 'package:flutter_lms/services/enrollment_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/app_config.dart';

class CourseDetailProvider extends ChangeNotifier {
  CourseDetailProvider(this._courseService, this._enrollmentService);

  final CourseService _courseService;
  final EnrollmentService _enrollmentService;

  Course? course;
  List<CourseSection> sections = const [];
  Enrollment? enrollment;

  bool isLoading = false;
  bool isEnrolling = false;
  bool _enrollmentConfirmed = false;
  String? errorMessage; // the course itself could not be loaded
  String? curriculumNotice; // the curriculum could not be shown
  String? enrollmentNotice;

  String _courseId = '';
  int _requestId = 0;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Active or completed enrollment gives access to the lessons.
  bool get isEnrolled =>
      _enrollmentConfirmed || (enrollment?.hasAccess ?? false);

  Future<void> load(String courseId) async {
    final request = ++_requestId;
    _courseId = courseId;
    course = null;
    sections = const [];
    enrollment = null;
    _enrollmentConfirmed = false;
    errorMessage = null;
    curriculumNotice = null;
    enrollmentNotice = null;
    isLoading = true;
    isEnrolling = false;
    _notify();

    try {
      final loaded = await _courseService.getCourse(courseId);
      if (!_isCurrent(courseId, request)) return;
      course = loaded;
    } on ApiException catch (error) {
      if (!_isCurrent(courseId, request)) return;
      errorMessage = error.message;
      isLoading = false;
      _notify();
      return;
    }

    await _loadEnrollment(courseId, request);
    if (!_isCurrent(courseId, request)) return;
    await _loadSections(courseId, request);
    if (!_isCurrent(courseId, request)) return;

    isLoading = false;
    _notify();
  }

  /// Looks for this course in the student's enrollments (a few pages at most).
  Future<void> _loadEnrollment(String courseId, int request) async {
    try {
      var page = 1;
      while (page <= 10) {
        final result = await _enrollmentService.getMyEnrollments(
          page: page,
          limit: AppConfig.defaultPageSize,
        );
        if (!_isCurrent(courseId, request)) return;
        for (final item in result.items) {
          if (item.courseId == courseId) {
            enrollment = item;
            return;
          }
        }
        if (!result.hasMore) break;
        page++;
      }
      if (_isCurrent(courseId, request)) enrollment = null;
    } on ApiException {
      if (_isCurrent(courseId, request)) {
        enrollment = null;
        enrollmentNotice = 'Unable to verify your enrollment right now.';
      }
    }
  }

  Future<void> refreshEnrollment() async {
    final id = _courseId;
    if (id.isEmpty) return;
    final request = ++_requestId;
    enrollmentNotice = null;
    _notify();
    await _loadEnrollment(id, request);
    if (_isCurrent(id, request)) _notify();
  }

  Future<void> _loadSections(String courseId, int request) async {
    try {
      final loaded = await _courseService.getSections(courseId);
      if (!_isCurrent(courseId, request)) return;
      sections = loaded;
      curriculumNotice = null;
      enrollmentNotice = null;
    } on ApiException catch (error) {
      if (!_isCurrent(courseId, request)) return;
      sections = const [];
      curriculumNotice = error.statusCode == 403
          ? 'Enroll in this course to see its curriculum.'
          : error.message;
    }
  }

  Future<void> refreshCurriculum() async {
    final id = _courseId;
    if (id.isEmpty) return;
    final request = ++_requestId;
    await _loadSections(id, request);
    if (_isCurrent(id, request)) _notify();
  }

  /// Returns null on success, or an error message to show.
  Future<String?> enroll() async {
    final id = _courseId;
    if (id.isEmpty) return 'The course is not loaded yet.';
    final request = _requestId;

    isEnrolling = true;
    _notify();

    String? error;
    try {
      await _enrollmentService.enroll(id);
      _enrollmentConfirmed = true;
    } on ApiException catch (e) {
      final mapped = ApiException.forEnrollment(e);
      error = mapped.message;
      _enrollmentConfirmed = mapped.errorCode == 'ENROLLMENT_ALREADY_EXISTS';
    }

    // Always sync with the backend (it may already be enrolled).
    if (!_isCurrent(id, request)) {
      if (!_disposed && id == _courseId) {
        isEnrolling = false;
        _notify();
      }
      return error;
    }
    await _loadEnrollment(id, request);
    if (!_isCurrent(id, request)) {
      if (!_disposed && id == _courseId) {
        isEnrolling = false;
        _notify();
      }
      return error;
    }
    if (isEnrolled) await _loadSections(id, request);

    isEnrolling = false;
    _notify();
    return error;
  }

  void reset() {
    _requestId++;
    _courseId = '';
    course = null;
    sections = const [];
    enrollment = null;
    _enrollmentConfirmed = false;
    isLoading = false;
    isEnrolling = false;
    errorMessage = null;
    curriculumNotice = null;
    enrollmentNotice = null;
    _notify();
  }

  bool _isCurrent(String id, int request) =>
      !_disposed && id == _courseId && request == _requestId;

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    super.dispose();
  }
}

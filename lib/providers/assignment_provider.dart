import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/assignment.dart';
import 'package:flutter_lms/services/assignment_service.dart';
import 'package:flutter_lms/services/enrollment_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class AssignmentProvider extends ChangeNotifier {
  AssignmentProvider(this._assignmentService, this._enrollmentService);

  final AssignmentService _assignmentService;
  final EnrollmentService _enrollmentService;

  List<Assignment> assignments = const [];
  Assignment? assignment;
  bool isLoading = false;
  String? errorMessage;
  String? partialErrorMessage;

  int _requestId = 0;
  String? _courseId;
  String _courseTitle = '';
  bool _allEnrolledCourses = false;
  bool _disposed = false;

  Future<void> loadCourse(String courseId, {String title = ''}) async {
    _courseId = courseId;
    _courseTitle = title;
    _allEnrolledCourses = false;
    await _load();
  }

  Future<void> loadForMyCourses() async {
    _courseId = null;
    _courseTitle = '';
    _allEnrolledCourses = true;
    await _load();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    final request = ++_requestId;
    assignments = const [];
    assignment = null;
    isLoading = true;
    errorMessage = null;
    partialErrorMessage = null;
    _notify();

    try {
      final courses = await _courseIdsForCurrentScope();
      if (!_isCurrent(request)) return;
      final loaded = <Assignment>[];
      final errors = <String>[];
      var successes = 0;
      for (final entry in courses.entries) {
        try {
          final values = await _assignmentService.getCourseAssignments(
            entry.key,
          );
          if (!_isCurrent(request)) return;
          successes++;
          loaded.addAll(values.map((item) => item.forCourse(entry.value)));
        } on ApiException catch (error) {
          if (!_isCurrent(request)) return;
          errors.add(error.message);
        }
      }
      if (!_isCurrent(request)) return;
      assignments = loaded;
      if (errors.isNotEmpty && successes == 0) {
        errorMessage = errors.first;
      } else if (errors.isNotEmpty) {
        partialErrorMessage =
            'Some course assignments could not be loaded. Pull down to retry.';
      }
    } on ApiException catch (error) {
      if (!_isCurrent(request)) return;
      errorMessage = error.message;
    } finally {
      if (_isCurrent(request)) {
        isLoading = false;
        _notify();
      }
    }
  }

  Future<Map<String, String>> _courseIdsForCurrentScope() async {
    final id = _courseId;
    if (!_allEnrolledCourses && id != null) {
      return {id: _courseTitle};
    }

    final courses = <String, String>{};
    var page = 1;
    while (true) {
      final result = await _enrollmentService.getMyEnrollments(
        page: page,
        status: null,
      );
      for (final enrollment in result.items) {
        if (!enrollment.hasAccess || enrollment.courseId.isEmpty) continue;
        courses[enrollment.courseId] =
            enrollment.course?.title ?? 'Enrolled course';
      }
      if (!result.hasMore) break;
      page++;
    }
    return courses;
  }

  Future<void> loadAssignment(String assignmentId) async {
    final request = ++_requestId;
    isLoading = true;
    assignment = null;
    errorMessage = null;
    _notify();
    try {
      final result = await _assignmentService.getAssignment(assignmentId);
      if (!_isCurrent(request)) return;
      assignment = result;
    } on ApiException catch (error) {
      if (!_isCurrent(request)) return;
      errorMessage = error.message;
    } finally {
      if (_isCurrent(request)) {
        isLoading = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _isCurrent(int request) => !_disposed && request == _requestId;

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    super.dispose();
  }
}

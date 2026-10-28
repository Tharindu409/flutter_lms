import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/course_section.dart';
import 'package:flutter_lms/models/instructor_assignment.dart';
import 'package:flutter_lms/services/instructor_assignment_service.dart';
import 'package:flutter_lms/services/instructor_lesson_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class InstructorAssignmentProvider extends ChangeNotifier {
  InstructorAssignmentProvider(this._service, this._lessonService);

  static const pageSize = 20;

  final InstructorAssignmentService _service;
  final InstructorLessonService _lessonService;

  String courseId = '';
  String courseTitle = '';
  String? selectedAssignmentId;
  InstructorAssignment? selectedAssignment;

  List<CourseSection> sections = const [];
  List<InstructorAssignment> assignments = const [];
  List<InstructorSubmission> submissions = const [];
  List<InstructorEnrollment> enrollments = const [];

  bool isLoadingSections = false;
  bool isLoadingAssignments = false;
  bool isLoadingSubmissions = false;
  bool isLoadingMoreSubmissions = false;
  bool isLoadingEnrollments = false;
  bool isLoadingMoreEnrollments = false;
  bool isBusy = false;
  bool isUploading = false;
  double? uploadProgress;
  bool hasMoreSubmissions = false;
  bool hasMoreEnrollments = false;
  String submissionStatus = '';
  String enrollmentStatus = '';

  String? sectionsError;
  String? assignmentsError;
  String? submissionsError;
  String? loadMoreSubmissionsError;
  String? enrollmentsError;
  String? loadMoreEnrollmentsError;

  int _sectionsRequest = 0;
  int _assignmentsRequest = 0;
  int _submissionsRequest = 0;
  int _enrollmentsRequest = 0;
  int _submissionPage = 1;
  int _enrollmentPage = 1;
  bool _disposed = false;
  CancelToken? _uploadCancelToken;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadCourse(String id, {required String title}) async {
    courseId = id;
    courseTitle = title;
    await Future.wait([loadSections(), loadAssignments()]);
  }

  Future<void> loadSections() async {
    if (courseId.isEmpty || _disposed) return;
    final request = ++_sectionsRequest;
    isLoadingSections = true;
    sectionsError = null;
    _notify();
    try {
      final result = await _lessonService.getCourseSections(courseId);
      if (_disposed || request != _sectionsRequest) return;
      sections = result;
    } on ApiException catch (error) {
      if (_disposed || request != _sectionsRequest) return;
      sectionsError = error.message;
    } finally {
      if (!_disposed && request == _sectionsRequest) {
        isLoadingSections = false;
        _notify();
      }
    }
  }

  Future<void> loadAssignments() async {
    if (courseId.isEmpty || _disposed) return;
    final request = ++_assignmentsRequest;
    isLoadingAssignments = true;
    assignmentsError = null;
    _notify();
    try {
      final result = await _service.getCourseAssignments(courseId);
      if (_disposed || request != _assignmentsRequest) return;
      assignments = result;
      final id = selectedAssignmentId;
      if (id != null) {
        selectedAssignment = _findAssignment(id);
      }
    } on ApiException catch (error) {
      if (_disposed || request != _assignmentsRequest) return;
      assignmentsError = error.message;
    } finally {
      if (!_disposed && request == _assignmentsRequest) {
        isLoadingAssignments = false;
        _notify();
      }
    }
  }

  void selectAssignment(InstructorAssignment assignment) {
    selectedAssignmentId = assignment.id;
    selectedAssignment = assignment;
  }

  Future<void> loadSubmissions(String assignmentId, {String? status}) async {
    selectedAssignmentId = assignmentId;
    if (status != null) submissionStatus = status;
    final request = ++_submissionsRequest;
    _submissionPage = 1;
    submissions = const [];
    isLoadingSubmissions = true;
    submissionsError = null;
    loadMoreSubmissionsError = null;
    hasMoreSubmissions = false;
    _notify();
    try {
      final result = await _service.getSubmissions(
        assignmentId,
        page: 1,
        limit: pageSize,
        status: submissionStatus,
      );
      if (_disposed || request != _submissionsRequest) return;
      submissions = result.items;
      _submissionPage = result.page;
      hasMoreSubmissions = result.hasMore;
    } on ApiException catch (error) {
      if (_disposed || request != _submissionsRequest) return;
      submissionsError = error.message;
    } finally {
      if (!_disposed && request == _submissionsRequest) {
        isLoadingSubmissions = false;
        _notify();
      }
    }
  }

  Future<void> loadMoreSubmissions() async {
    final id = selectedAssignmentId;
    if (id == null ||
        isLoadingSubmissions ||
        isLoadingMoreSubmissions ||
        !hasMoreSubmissions) {
      return;
    }
    final request = _submissionsRequest;
    isLoadingMoreSubmissions = true;
    loadMoreSubmissionsError = null;
    _notify();
    try {
      final result = await _service.getSubmissions(
        id,
        page: _submissionPage + 1,
        limit: pageSize,
        status: submissionStatus,
      );
      if (_disposed || request != _submissionsRequest) return;
      submissions = [...submissions, ...result.items];
      _submissionPage = result.page;
      hasMoreSubmissions = result.hasMore;
    } on ApiException catch (error) {
      if (!_disposed && request == _submissionsRequest) {
        loadMoreSubmissionsError = error.message;
      }
    } finally {
      if (!_disposed && request == _submissionsRequest) {
        isLoadingMoreSubmissions = false;
        _notify();
      }
    }
  }

  Future<void> loadEnrollments({String? status}) async {
    if (courseId.isEmpty || _disposed) return;
    if (status != null) enrollmentStatus = status;
    final request = ++_enrollmentsRequest;
    _enrollmentPage = 1;
    enrollments = const [];
    isLoadingEnrollments = true;
    enrollmentsError = null;
    loadMoreEnrollmentsError = null;
    hasMoreEnrollments = false;
    _notify();
    try {
      final result = await _service.getCourseEnrollments(
        courseId,
        page: 1,
        limit: pageSize,
        status: enrollmentStatus,
      );
      if (_disposed || request != _enrollmentsRequest) return;
      enrollments = result.items;
      _enrollmentPage = result.page;
      hasMoreEnrollments = result.hasMore;
    } on ApiException catch (error) {
      if (_disposed || request != _enrollmentsRequest) return;
      enrollmentsError = error.message;
    } finally {
      if (!_disposed && request == _enrollmentsRequest) {
        isLoadingEnrollments = false;
        _notify();
      }
    }
  }

  Future<void> loadMoreEnrollments() async {
    if (isLoadingEnrollments ||
        isLoadingMoreEnrollments ||
        !hasMoreEnrollments ||
        courseId.isEmpty) {
      return;
    }
    final request = _enrollmentsRequest;
    isLoadingMoreEnrollments = true;
    loadMoreEnrollmentsError = null;
    _notify();
    try {
      final result = await _service.getCourseEnrollments(
        courseId,
        page: _enrollmentPage + 1,
        limit: pageSize,
        status: enrollmentStatus,
      );
      if (_disposed || request != _enrollmentsRequest) return;
      enrollments = [...enrollments, ...result.items];
      _enrollmentPage = result.page;
      hasMoreEnrollments = result.hasMore;
    } on ApiException catch (error) {
      if (!_disposed && request == _enrollmentsRequest) {
        loadMoreEnrollmentsError = error.message;
      }
    } finally {
      if (!_disposed && request == _enrollmentsRequest) {
        isLoadingMoreEnrollments = false;
        _notify();
      }
    }
  }

  Future<String?> createAssignment(Map<String, dynamic> body) {
    return _mutateAssignment(() => _service.createAssignment(courseId, body));
  }

  Future<String?> updateAssignment(
    String assignmentId,
    Map<String, dynamic> body,
  ) {
    return _mutateAssignment(
      () => _service.updateAssignment(assignmentId, body),
    );
  }

  Future<String?> publishAssignment(String assignmentId) {
    return _mutateAssignment(() => _service.publishAssignment(assignmentId));
  }

  Future<String?> deleteAssignment(String assignmentId) {
    return _mutateAssignment(() => _service.deleteAssignment(assignmentId));
  }

  Future<String?> deleteAttachment(String assignmentId) {
    return _mutateAssignment(() => _service.deleteAttachment(assignmentId));
  }

  Future<String?> _mutateAssignment(Future<void> Function() action) async {
    if (_disposed) return null;
    if (isBusy) return 'Please wait for the current action to finish.';
    isBusy = true;
    _notify();
    try {
      await action();
    } on ApiException catch (error) {
      return error.message;
    } finally {
      if (!_disposed) {
        isBusy = false;
        _notify();
      }
    }
    if (_disposed) return null;
    await loadAssignments();
    return null;
  }

  Future<String?> uploadAttachment(
    String assignmentId,
    String path,
    String fileName,
  ) async {
    if (_disposed) return null;
    if (isBusy) return 'Please wait for the current action to finish.';
    final token = CancelToken();
    _uploadCancelToken = token;
    isUploading = true;
    uploadProgress = 0;
    _notify();
    final error = await _mutateAssignment(() {
      return _service.uploadAttachment(
        assignmentId,
        path,
        fileName,
        cancelToken: token,
        onSendProgress: (sent, total) {
          if (_disposed || total <= 0) return;
          uploadProgress = (sent / total).clamp(0, 1).toDouble();
          _notify();
        },
      );
    });
    if (!_disposed) {
      isUploading = false;
      uploadProgress = null;
      _uploadCancelToken = null;
      _notify();
    }
    return error;
  }

  void cancelUpload() => _uploadCancelToken?.cancel();

  Future<String?> gradeSubmission(
    String submissionId,
    Map<String, dynamic> body,
  ) async {
    if (_disposed) return null;
    if (isBusy) return 'Please wait for the current action to finish.';
    isBusy = true;
    _notify();
    try {
      await _service.gradeSubmission(submissionId, body);
    } on ApiException catch (error) {
      return error.message;
    } finally {
      if (!_disposed) {
        isBusy = false;
        _notify();
      }
    }
    final assignmentId = selectedAssignmentId;
    if (!_disposed && assignmentId != null) {
      await loadSubmissions(assignmentId);
    }
    return null;
  }

  InstructorAssignment? _findAssignment(String id) {
    for (final item in assignments) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _sectionsRequest++;
    _assignmentsRequest++;
    _submissionsRequest++;
    _enrollmentsRequest++;
    _uploadCancelToken?.cancel();
    super.dispose();
  }
}

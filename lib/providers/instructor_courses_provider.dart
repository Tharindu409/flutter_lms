import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/course.dart';
import 'package:flutter_lms/services/instructor_course_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:image_picker/image_picker.dart';

class InstructorCoursesProvider extends ChangeNotifier {
  InstructorCoursesProvider(this._service);

  final InstructorCourseService _service;

  static const pageSize = 20;

  List<Course> courses = [];
  Course? selectedCourse;
  String? status; // null shows every status
  String search = '';

  bool isLoading = false; // first page or refresh
  bool isLoadingMore = false;
  bool isBusy = false; // create, update, upload, publish or archive
  double? uploadProgress;
  bool isLoadingCourse = false;
  String? courseError;
  String? errorMessage;
  String? loadMoreError;
  bool hasMore = false;

  /// The course created most recently, so the form can open its builder.
  Course? lastCreated;

  int _page = 1;
  int _requestId = 0;
  int _courseRequestId = 0;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh() async {
    final request = ++_requestId;
    isLoading = true;
    errorMessage = null;
    loadMoreError = null;
    _notify();

    try {
      final result = await _service.getMyCourses(
        page: 1,
        limit: pageSize,
        status: status,
        search: search,
      );
      if (_disposed || request != _requestId) return;
      courses = result.items;
      _page = result.page;
      hasMore = result.hasMore;
    } on ApiException catch (error) {
      if (_disposed || request != _requestId) return;
      courses = [];
      hasMore = false;
      errorMessage = error.message;
    } finally {
      if (!_disposed && request == _requestId) {
        isLoading = false;
        _notify();
      }
    }
  }

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore) return;

    final request = _requestId;
    isLoadingMore = true;
    loadMoreError = null;
    _notify();

    try {
      final result = await _service.getMyCourses(
        page: _page + 1,
        limit: pageSize,
        status: status,
        search: search,
      );
      if (!_disposed && request == _requestId) {
        courses = [...courses, ...result.items];
        _page = result.page;
        hasMore = result.hasMore;
      }
    } on ApiException catch (error) {
      if (!_disposed && request == _requestId) loadMoreError = error.message;
    } finally {
      if (!_disposed && request == _requestId) {
        isLoadingMore = false;
        _notify();
      }
    }
  }

  Future<void> setStatus(String? value) {
    status = value;
    return refresh();
  }

  Future<void> setSearch(String value) {
    search = value.trim();
    return refresh();
  }

  /// Throws ApiException (403 when the course belongs to another instructor).
  Future<Course> fetchCourse(String courseId) {
    return _service.getMyCourse(courseId);
  }

  Future<void> loadCourse(String courseId) async {
    final request = ++_courseRequestId;
    isLoadingCourse = true;
    courseError = null;
    _notify();
    try {
      final result = await _service.getMyCourse(courseId);
      if (_disposed || request != _courseRequestId) return;
      selectedCourse = result;
    } on ApiException catch (error) {
      if (_disposed || request != _courseRequestId) return;
      courseError = error.message;
    } finally {
      if (!_disposed && request == _courseRequestId) {
        isLoadingCourse = false;
        _notify();
      }
    }
  }

  // Every action returns null on success, or an error message to show.

  Future<String?> createCourse(Map<String, dynamic> body) {
    return _runBusy(() async {
      lastCreated = await _service.createCourse(body);
    });
  }

  Future<String?> updateCourse(String courseId, Map<String, dynamic> body) {
    return _runBusy(() => _service.updateCourse(courseId, body))
        .then((error) => _refreshSelectedCourse(courseId, error));
  }

  Future<String?> uploadThumbnail(String courseId, XFile file) {
    return _runBusy(() => _service.uploadThumbnail(
      courseId,
      file,
      onSendProgress: (sent, total) {
        if (_disposed || total <= 0) return;
        uploadProgress = (sent / total).clamp(0, 1).toDouble();
        _notify();
      },
    )).then((error) => _refreshSelectedCourse(courseId, error));
  }

  Future<String?> removeThumbnail(String courseId) {
    return _runBusy(() => _service.removeThumbnail(courseId))
        .then((error) => _refreshSelectedCourse(courseId, error));
  }

  Future<String?> publishCourse(String courseId) {
    return _runBusy(() => _service.publishCourse(courseId))
        .then((error) => _refreshSelectedCourse(courseId, error));
  }

  Future<String?> archiveCourse(String courseId) {
    return _runBusy(() => _service.archiveCourse(courseId))
        .then((error) => _refreshSelectedCourse(courseId, error));
  }

  Future<String?> _runBusy(Future<void> Function() action) async {
    if (_disposed) return null;
    if (isBusy) return 'Please wait for the current action to finish.';
    isBusy = true;
    _notify();

    try {
      await action();
    } on ApiException catch (error) {
      final backendMessage = error.backendMessage?.trim();
      if (error.statusCode == 403) {
        return 'You do not have access to this course';
      }
      if (const [400, 409, 422].contains(error.statusCode) &&
          backendMessage != null &&
          backendMessage.isNotEmpty) {
        return backendMessage;
      }
      return error.message;
    } finally {
      if (!_disposed) {
        isBusy = false;
        uploadProgress = null;
        _notify();
      }
    }

    if (_disposed) return null;
    await refresh();
    return null;
  }

  Future<String?> _refreshSelectedCourse(String courseId, String? error) async {
    if (error != null || _disposed || selectedCourse?.id != courseId) {
      return error;
    }
    await loadCourse(courseId);
    return courseError;
  }

  void reset() {
    _requestId++;
    _courseRequestId++;
    courses = [];
    selectedCourse = null;
    status = null;
    search = '';
    isLoading = false;
    isLoadingMore = false;
    isBusy = false;
    uploadProgress = null;
    isLoadingCourse = false;
    courseError = null;
    errorMessage = null;
    loadMoreError = null;
    hasMore = false;
    lastCreated = null;
    _page = 1;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    _courseRequestId++;
    super.dispose();
  }
}

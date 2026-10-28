import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/course.dart';
import 'package:flutter_lms/services/instructor_course_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:image_picker/image_picker.dart';

class InstructorCoursesProvider extends ChangeNotifier {
  InstructorCoursesProvider(this._service);

  final InstructorCourseService _service;

  static const pageSize = 10;

  List<Course> courses = [];
  String? status; // null shows every status
  String search = '';

  bool isLoading = false; // first page or refresh
  bool isLoadingMore = false;
  bool isBusy = false; // create, update, upload, publish or archive
  String? errorMessage;
  String? loadMoreError;
  bool hasMore = false;

  /// The course created most recently, so the form can open its builder.
  Course? lastCreated;

  int _page = 1;
  int _requestId = 0;

  Future<void> refresh() async {
    final request = ++_requestId;
    isLoading = true;
    errorMessage = null;
    loadMoreError = null;
    notifyListeners();

    try {
      final result = await _service.getMyCourses(
        page: 1,
        limit: pageSize,
        status: status,
        search: search,
      );
      if (request != _requestId) return;
      courses = result.items;
      _page = result.page;
      hasMore = result.hasMore;
    } on ApiException catch (error) {
      if (request != _requestId) return;
      courses = [];
      hasMore = false;
      errorMessage = error.message;
    } finally {
      if (request == _requestId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore) return;

    final request = _requestId;
    isLoadingMore = true;
    loadMoreError = null;
    notifyListeners();

    try {
      final result = await _service.getMyCourses(
        page: _page + 1,
        limit: pageSize,
        status: status,
        search: search,
      );
      if (request == _requestId) {
        courses = [...courses, ...result.items];
        _page = result.page;
        hasMore = result.hasMore;
      }
    } on ApiException catch (error) {
      if (request == _requestId) loadMoreError = error.message;
    } finally {
      isLoadingMore = false;
      notifyListeners();
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

  // Every action returns null on success, or an error message to show.

  Future<String?> createCourse(Map<String, dynamic> body) {
    return _runBusy(() async {
      lastCreated = await _service.createCourse(body);
    });
  }

  Future<String?> updateCourse(String courseId, Map<String, dynamic> body) {
    return _runBusy(() => _service.updateCourse(courseId, body));
  }

  Future<String?> uploadThumbnail(String courseId, XFile file) {
    return _runBusy(() => _service.uploadThumbnail(courseId, file));
  }

  Future<String?> removeThumbnail(String courseId) {
    return _runBusy(() => _service.removeThumbnail(courseId));
  }

  Future<String?> publishCourse(String courseId) {
    return _runBusy(() => _service.publishCourse(courseId));
  }

  Future<String?> archiveCourse(String courseId) {
    return _runBusy(() => _service.archiveCourse(courseId));
  }

  Future<String?> _runBusy(Future<void> Function() action) async {
    isBusy = true;
    notifyListeners();

    try {
      await action();
    } on ApiException catch (error) {
      isBusy = false;
      notifyListeners();
      return error.message;
    }

    await refresh(); // keep the list in sync with the backend
    isBusy = false;
    notifyListeners();
    return null;
  }

  void reset() {
    _requestId++;
    courses = [];
    status = null;
    search = '';
    isLoading = false;
    isLoadingMore = false;
    isBusy = false;
    errorMessage = null;
    loadMoreError = null;
    hasMore = false;
    lastCreated = null;
    _page = 1;
    notifyListeners();
  }
}

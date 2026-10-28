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
  bool _disposed = false;
  double? thumbnailUploadProgress;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh() async {
    final request = ++_requestId;
    isLoading = true;
    isLoadingMore = false;
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
    thumbnailUploadProgress = 0;
    _notify();
    return _runBusy(
      () => _service.uploadThumbnail(
        courseId,
        file,
        onSendProgress: (sent, total) {
          if (_disposed || total <= 0) return;
          thumbnailUploadProgress = (sent / total).clamp(0, 1).toDouble();
          _notify();
        },
      ),
    ).whenComplete(() {
      if (_disposed) return;
      thumbnailUploadProgress = null;
      _notify();
    });
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
    if (_disposed) return null;
    if (isBusy) return 'Please wait for the current action to finish.';
    isBusy = true;
    _notify();

    try {
      await action();
      if (!_disposed) await refresh();
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'Unable to complete this action. Please try again.';
    } finally {
      if (!_disposed) {
        isBusy = false;
        _notify();
      }
    }
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
    thumbnailUploadProgress = null;
    _page = 1;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    super.dispose();
  }
}

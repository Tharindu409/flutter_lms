import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/enrollment.dart';
import 'package:flutter_lms/services/enrollment_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/app_config.dart';

class MyCoursesProvider extends ChangeNotifier {
  MyCoursesProvider(this._service);

  final EnrollmentService _service;

  static const pageSize = AppConfig.defaultPageSize;
  static const active = 'ACTIVE';
  static const completed = 'COMPLETED';

  List<Enrollment> enrollments = [];
  String status = active;

  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;
  String? loadMoreError;
  bool hasMore = false;

  int _page = 1;
  int _requestId = 0;
  bool _disposed = false;

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
      final result = await _service.getMyEnrollments(
        page: 1,
        limit: pageSize,
        status: status,
      );
      if (request != _requestId) return;
      enrollments = result.items;
      _page = result.page;
      hasMore = result.hasMore;
    } on ApiException catch (error) {
      if (request != _requestId) return;
      enrollments = [];
      hasMore = false;
      errorMessage = error.message;
    } finally {
      if (request == _requestId) {
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
      final result = await _service.getMyEnrollments(
        page: _page + 1,
        limit: pageSize,
        status: status,
      );
      if (request == _requestId) {
        enrollments = [...enrollments, ...result.items];
        _page = result.page;
        hasMore = result.hasMore;
      }
    } on ApiException catch (error) {
      if (request == _requestId) loadMoreError = error.message;
    } finally {
      if (request == _requestId) {
        isLoadingMore = false;
        _notify();
      }
    }
  }

  Future<void> setStatus(String value) {
    if (status == value) return Future.value();
    status = value;
    enrollments = [];
    hasMore = false;
    _page = 1;
    isLoadingMore = false;
    return refresh();
  }

  Future<Enrollment?> loadEnrollment(String enrollmentId) async {
    final request = _requestId;
    try {
      final result = await _service.getEnrollment(enrollmentId);
      return request == _requestId && !_disposed ? result : null;
    } on ApiException catch (error) {
      if (request != _requestId || _disposed) return null;
      errorMessage = error.message;
      _notify();
      return null;
    }
  }

  void reset() {
    _requestId++;
    enrollments = [];
    status = active;
    isLoading = false;
    isLoadingMore = false;
    errorMessage = null;
    loadMoreError = null;
    hasMore = false;
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

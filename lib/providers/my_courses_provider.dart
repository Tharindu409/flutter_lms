import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/enrollment.dart';
import 'package:flutter_lms/services/enrollment_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class MyCoursesProvider extends ChangeNotifier {
  MyCoursesProvider(this._service);

  final EnrollmentService _service;

  static const pageSize = 10;
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

  Future<void> refresh() async {
    final request = ++_requestId;
    isLoading = true;
    errorMessage = null;
    loadMoreError = null;
    notifyListeners();

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
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setStatus(String value) {
    status = value;
    return refresh();
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
    notifyListeners();
  }
}

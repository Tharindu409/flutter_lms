import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/instructor_summary.dart';
import 'package:flutter_lms/services/instructor_course_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class InstructorDashboardProvider extends ChangeNotifier {
  InstructorDashboardProvider(this._service);

  final InstructorCourseService _service;

  InstructorSummary? summary;
  bool isLoading = false;
  String? errorMessage;
  int _requestGeneration = 0;
  bool _disposed = false;

  Future<void> load() async {
    if (_disposed || isLoading) return;
    final request = ++_requestGeneration;
    isLoading = true;
    errorMessage = null;
    _notify();

    try {
      final result = await _service.getDashboard();
      if (_isCurrent(request)) summary = result;
    } on ApiException catch (error) {
      if (_isCurrent(request)) errorMessage = error.message;
    } finally {
      if (_isCurrent(request)) {
        isLoading = false;
        _notify();
      }
    }
  }

  void reset() {
    _requestGeneration++;
    summary = null;
    isLoading = false;
    errorMessage = null;
    _notify();
  }

  bool _isCurrent(int request) => !_disposed && request == _requestGeneration;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration++;
    super.dispose();
  }
}

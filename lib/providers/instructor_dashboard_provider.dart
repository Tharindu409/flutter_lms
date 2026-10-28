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

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      summary = await _service.getDashboard();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    summary = null;
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }
}

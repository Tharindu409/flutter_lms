import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/quiz.dart';
import 'package:flutter_lms/services/quiz_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class QuizProvider extends ChangeNotifier {
  QuizProvider(this._service);

  final QuizService _service;

  List<Quiz> quizzes = const [];
  String courseId = '';
  bool isLoading = false;
  String? errorMessage;
  int _requestId = 0;
  bool _disposed = false;

  Future<void> load(String courseId) async {
    final request = ++_requestId;
    this.courseId = courseId;
    quizzes = const [];
    isLoading = true;
    errorMessage = null;
    _notify();
    try {
      final result = await _service.getCourseQuizzes(courseId);
      if (_disposed || request != _requestId) return;
      quizzes = result;
    } on ApiException catch (error) {
      if (_disposed || request != _requestId) return;
      errorMessage = error.message;
    } finally {
      if (!_disposed && request == _requestId) {
        isLoading = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    super.dispose();
  }
}

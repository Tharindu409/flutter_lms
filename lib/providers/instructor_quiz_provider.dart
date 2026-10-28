import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/course_section.dart';
import 'package:flutter_lms/models/paged_result.dart';
import 'package:flutter_lms/models/quiz.dart';
import 'package:flutter_lms/services/instructor_lesson_service.dart';
import 'package:flutter_lms/services/instructor_quiz_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class InstructorQuizProvider extends ChangeNotifier {
  InstructorQuizProvider(this._service, this._lessonService);

  static const pageSize = 20;

  final InstructorQuizService _service;
  final InstructorLessonService _lessonService;

  String courseId = '';
  String? selectedQuizId;
  List<CourseSection> sections = const [];
  List<Quiz> quizzes = const [];
  List<QuizAttempt> attempts = const [];
  Quiz? quiz;

  bool isLoadingSections = false;
  bool isLoadingQuizzes = false;
  bool isLoadingQuiz = false;
  bool isLoadingAttempts = false;
  bool isLoadingMoreAttempts = false;
  bool isBusy = false;
  bool hasMoreAttempts = false;

  String? sectionsError;
  String? quizzesError;
  String? quizError;
  String? attemptsError;
  String? loadMoreAttemptsError;

  int _sectionsRequest = 0;
  int _quizzesRequest = 0;
  int _quizRequest = 0;
  int _attemptsRequest = 0;
  int _attemptsPage = 1;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadSections(String id) async {
    final request = ++_sectionsRequest;
    isLoadingSections = true;
    sectionsError = null;
    _notify();
    try {
      final result = await _lessonService.getCourseSections(id);
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

  Future<void> loadQuizzes(String id) async {
    courseId = id;
    final request = ++_quizzesRequest;
    isLoadingQuizzes = true;
    quizzesError = null;
    _notify();
    try {
      final result = await _service.getCourseQuizzes(id);
      if (_disposed || request != _quizzesRequest) return;
      quizzes = result;
    } on ApiException catch (error) {
      if (_disposed || request != _quizzesRequest) return;
      quizzesError = error.message;
    } finally {
      if (!_disposed && request == _quizzesRequest) {
        isLoadingQuizzes = false;
        _notify();
      }
    }
  }

  Future<void> loadQuiz(String id) async {
    selectedQuizId = id;
    final request = ++_quizRequest;
    isLoadingQuiz = true;
    quizError = null;
    _notify();
    try {
      final result = await _service.getQuiz(id);
      if (_disposed || request != _quizRequest) return;
      quiz = result;
    } on ApiException catch (error) {
      if (_disposed || request != _quizRequest) return;
      quizError = error.message;
    } finally {
      if (!_disposed && request == _quizRequest) {
        isLoadingQuiz = false;
        _notify();
      }
    }
  }

  Future<void> loadAttempts(String id) async {
    selectedQuizId = id;
    final request = ++_attemptsRequest;
    _attemptsPage = 1;
    attempts = const [];
    isLoadingAttempts = true;
    attemptsError = null;
    loadMoreAttemptsError = null;
    hasMoreAttempts = false;
    _notify();
    try {
      final result = await _service.getAttempts(id, page: 1, limit: pageSize);
      if (_disposed || request != _attemptsRequest) return;
      _setAttemptsPage(result);
    } on ApiException catch (error) {
      if (_disposed || request != _attemptsRequest) return;
      attemptsError = error.message;
    } finally {
      if (!_disposed && request == _attemptsRequest) {
        isLoadingAttempts = false;
        _notify();
      }
    }
  }

  Future<void> loadMoreAttempts() async {
    final id = selectedQuizId;
    if (id == null ||
        isLoadingAttempts ||
        isLoadingMoreAttempts ||
        !hasMoreAttempts) {
      return;
    }
    final request = _attemptsRequest;
    isLoadingMoreAttempts = true;
    loadMoreAttemptsError = null;
    _notify();
    try {
      final result = await _service.getAttempts(
        id,
        page: _attemptsPage + 1,
        limit: pageSize,
      );
      if (_disposed || request != _attemptsRequest) return;
      attempts = [...attempts, ...result.items];
      _attemptsPage = result.page;
      hasMoreAttempts = result.hasMore;
    } on ApiException catch (error) {
      if (!_disposed && request == _attemptsRequest) {
        loadMoreAttemptsError = error.message;
      }
    } finally {
      if (!_disposed && request == _attemptsRequest) {
        isLoadingMoreAttempts = false;
        _notify();
      }
    }
  }

  void _setAttemptsPage(PagedResult<QuizAttempt> result) {
    attempts = result.items;
    _attemptsPage = result.page;
    hasMoreAttempts = result.hasMore;
  }

  Future<String?> createQuiz(String id, Map<String, dynamic> body) async {
    courseId = id;
    return _mutate(() => _service.createQuiz(id, body), refreshQuiz: false);
  }

  Future<String?> updateQuiz(String id, Map<String, dynamic> changed) {
    if (changed.isEmpty) return Future.value(null);
    return _mutate(() => _service.updateQuiz(id, changed));
  }

  Future<String?> addQuestion(String quizId, Map<String, dynamic> body) {
    return _mutate(() => _service.addQuestion(quizId, body));
  }

  Future<String?> updateQuestion(
    String questionId,
    Map<String, dynamic> changed,
  ) {
    if (changed.isEmpty) return Future.value(null);
    return _mutate(() => _service.updateQuestion(questionId, changed));
  }

  Future<String?> deleteQuestion(String questionId) {
    return _mutate(() => _service.deleteQuestion(questionId));
  }

  Future<String?> publishQuiz(String quizId) {
    return _mutate(() => _service.publishQuiz(quizId));
  }

  Future<String?> deleteQuiz(String quizId) async {
    final error = await _mutate(
      () => _service.deleteQuiz(quizId),
      refreshQuiz: false,
    );
    if (error == null && selectedQuizId == quizId && !_disposed) {
      selectedQuizId = null;
      quiz = null;
    }
    return error;
  }

  Future<String?> _mutate(
    Future<void> Function() action, {
    bool refreshQuiz = true,
  }) async {
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
    if (refreshQuiz && selectedQuizId != null) {
      await loadQuiz(selectedQuizId!);
    }
    if (courseId.isNotEmpty) await loadQuizzes(courseId);
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _sectionsRequest++;
    _quizzesRequest++;
    _quizRequest++;
    _attemptsRequest++;
    super.dispose();
  }
}

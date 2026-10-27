import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/course_progress.dart';
import 'package:flutter_lms/models/course_section.dart';
import 'package:flutter_lms/models/lesson.dart';
import 'package:flutter_lms/services/course_service.dart';
import 'package:flutter_lms/services/enrollment_service.dart';
import 'package:flutter_lms/services/learning_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

enum ProgressStatus { idle, loading, loaded, refreshFailed }

class LearningProvider extends ChangeNotifier {
  LearningProvider(
    this._courseService,
    this._learningService, [
    this._enrollmentService,
  ]);

  final CourseService _courseService;
  final LearningService _learningService;
  final EnrollmentService? _enrollmentService;

  String courseId = '';
  String courseTitle = '';
  String? _enrollmentId;
  List<CourseSection> sections = const [];
  final Map<String, List<Lesson>> lessonsBySection = {};
  final Map<String, String> sectionErrors = {};
  CourseProgress? progress;

  bool isLoading = false;
  String? errorMessage;
  String? progressNotice;
  int? lastActionStatusCode;
  ProgressStatus progressStatus = ProgressStatus.idle;
  DateTime? lastRefreshedAt;

  int _loadGeneration = 0;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  List<Lesson> get allLessons => [
    for (final section in sections) ...?lessonsBySection[section.id],
  ];

  List<Lesson> lessonsOf(String sectionId) =>
      lessonsBySection[sectionId] ?? const [];

  String? statusOf(String lessonId) => progress?.statusOf(lessonId);

  Lesson? nextLesson(String lessonId) {
    final lessons = allLessons;
    final index = lessons.indexWhere((lesson) => lesson.id == lessonId);
    if (index == -1 || index + 1 >= lessons.length) return null;
    return lessons[index + 1];
  }

  Lesson? previousLesson(String lessonId) {
    final lessons = allLessons;
    final index = lessons.indexWhere((lesson) => lesson.id == lessonId);
    if (index <= 0) return null;
    return lessons[index - 1];
  }

  Future<void> load(
    String id, {
    String title = '',
    String? enrollmentId,
  }) async {
    final generation = ++_loadGeneration;
    courseId = id;
    courseTitle = title;
    _enrollmentId = enrollmentId;
    sections = const [];
    lessonsBySection.clear();
    sectionErrors.clear();
    progress = null;
    errorMessage = null;
    progressNotice = null;
    lastActionStatusCode = null;
    lastRefreshedAt = null;
    progressStatus = ProgressStatus.loading;
    isLoading = true;
    _notify();

    try {
      final loaded = await _courseService.getSections(id);
      if (!_isCurrent(id, generation)) return;
      sections = loaded;
    } on ApiException catch (error) {
      if (!_isCurrent(id, generation)) return;
      errorMessage = error.message;
      isLoading = false;
      _notify();
      return;
    }

    final current = sections;
    await Future.wait([
      for (final section in current)
        _loadSectionLessons(id, generation, section.id),
      _loadProgress(id, generation),
    ]);
    if (!_isCurrent(id, generation)) return;

    isLoading = false;
    _notify();
  }

  Future<void> _loadSectionLessons(
    String id,
    int generation,
    String sectionId,
  ) async {
    try {
      final lessons = await _courseService.getLessons(sectionId);
      if (_isCurrent(id, generation)) lessonsBySection[sectionId] = lessons;
    } on ApiException catch (error) {
      if (_isCurrent(id, generation)) sectionErrors[sectionId] = error.message;
    }
  }

  Future<void> _loadProgress(String id, int generation) async {
    progressStatus = ProgressStatus.loading;
    _notify();
    try {
      final result = _enrollmentId != null && _enrollmentId!.isNotEmpty
          ? await _enrollmentService!.getEnrollmentProgress(_enrollmentId!)
          : await _learningService.getCourseProgress(id);
      if (!_isCurrent(id, generation)) return;
      progress = result;
      progressStatus = ProgressStatus.loaded;
      progressNotice = null;
      lastRefreshedAt = DateTime.now();
    } on ApiException {
      if (!_isCurrent(id, generation)) return;
      progressStatus = ProgressStatus.refreshFailed;
      progressNotice = 'Progress may be out of date.';
    }
    _notify();
  }

  Future<void> refreshProgress() async {
    final id = courseId;
    final generation = _loadGeneration;
    if (id.isEmpty) return;
    await _loadProgress(id, generation);
  }

  Future<String?> startLesson(String lessonId) async {
    if (statusOf(lessonId) == CourseProgress.completed) return null;
    final id = courseId;
    final generation = _loadGeneration;
    try {
      await _learningService.startLesson(lessonId);
      lastActionStatusCode = null;
    } on ApiException catch (error) {
      lastActionStatusCode = error.statusCode;
      return error.message;
    }
    if (_isCurrent(id, generation)) await refreshProgress();
    return null;
  }

  Future<String?> completeLesson(String lessonId) async {
    final id = courseId;
    final generation = _loadGeneration;
    try {
      await _learningService.completeLesson(lessonId);
      lastActionStatusCode = null;
    } on ApiException catch (error) {
      lastActionStatusCode = error.statusCode;
      return error.message;
    }
    if (_isCurrent(id, generation)) await refreshProgress();
    return null;
  }

  Future<Lesson> fetchLesson(String lessonId) =>
      _courseService.getLesson(lessonId);

  bool _isCurrent(String id, int generation) =>
      !_disposed && id == courseId && generation == _loadGeneration;

  void reset() {
    _loadGeneration++;
    courseId = '';
    courseTitle = '';
    _enrollmentId = null;
    sections = const [];
    lessonsBySection.clear();
    sectionErrors.clear();
    progress = null;
    isLoading = false;
    errorMessage = null;
    progressNotice = null;
    lastActionStatusCode = null;
    progressStatus = ProgressStatus.idle;
    lastRefreshedAt = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

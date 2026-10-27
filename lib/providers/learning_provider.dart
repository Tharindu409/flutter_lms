import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/course_progress.dart';
import 'package:flutter_lms/models/course_section.dart';
import 'package:flutter_lms/models/lesson.dart';
import 'package:flutter_lms/services/course_service.dart';
import 'package:flutter_lms/services/learning_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class LearningProvider extends ChangeNotifier {
  LearningProvider(this._courseService, this._learningService);

  final CourseService _courseService;
  final LearningService _learningService;

  String courseId = '';
  String courseTitle = '';
  List<CourseSection> sections = const [];
  final Map<String, List<Lesson>> lessonsBySection = {};
  final Map<String, String> sectionErrors = {};
  CourseProgress? progress; // always the backend values

  bool isLoading = false;
  String? errorMessage;
  String? progressNotice;

  /// Lessons of the whole course in learning order.
  List<Lesson> get allLessons => [
    for (final section in sections) ...?lessonsBySection[section.id],
  ];

  List<Lesson> lessonsOf(String sectionId) =>
      lessonsBySection[sectionId] ?? const [];

  String statusOf(String lessonId) =>
      progress?.statusOf(lessonId) ?? CourseProgress.notStarted;

  Lesson? nextLesson(String lessonId) {
    final lessons = allLessons;
    final index = lessons.indexWhere((l) => l.id == lessonId);
    if (index == -1 || index + 1 >= lessons.length) return null;
    return lessons[index + 1];
  }

  Lesson? previousLesson(String lessonId) {
    final lessons = allLessons;
    final index = lessons.indexWhere((l) => l.id == lessonId);
    if (index <= 0) return null;
    return lessons[index - 1];
  }

  Future<void> load(String id, {String title = ''}) async {
    courseId = id;
    courseTitle = title;
    sections = const [];
    lessonsBySection.clear();
    sectionErrors.clear();
    progress = null;
    errorMessage = null;
    progressNotice = null;
    isLoading = true;
    notifyListeners();

    try {
      final loaded = await _courseService.getSections(id);
      if (id != courseId) return;
      sections = loaded;
    } on ApiException catch (error) {
      if (id != courseId) return;
      errorMessage = error.message;
      isLoading = false;
      notifyListeners();
      return;
    }

    final current = sections;
    await Future.wait([
      for (final section in current) _loadSectionLessons(id, section.id),
      _loadProgress(id),
    ]);
    if (id != courseId) return;

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSectionLessons(String id, String sectionId) async {
    try {
      final lessons = await _courseService.getLessons(sectionId);
      if (id == courseId) lessonsBySection[sectionId] = lessons;
    } on ApiException catch (error) {
      if (id == courseId) sectionErrors[sectionId] = error.message;
    }
  }

  Future<void> _loadProgress(String id) async {
    try {
      final result = await _learningService.getCourseProgress(id);
      if (id != courseId) return;
      progress = result;
      progressNotice = null;
    } on ApiException catch (error) {
      if (id == courseId) progressNotice = error.message;
    }
  }

  /// Reloads the progress the backend calculated.
  Future<void> refreshProgress() async {
    final id = courseId;
    if (id.isEmpty) return;
    await _loadProgress(id);
    if (id == courseId) notifyListeners();
  }

  /// Returns null on success, or an error message to show.
  Future<String?> startLesson(String lessonId) async {
    // Starting again would turn a finished lesson back into IN_PROGRESS.
    if (statusOf(lessonId) == CourseProgress.completed) return null;

    try {
      await _learningService.startLesson(lessonId);
    } on ApiException catch (error) {
      return error.message;
    }
    await refreshProgress();
    return null;
  }

  /// Returns null on success, or an error message to show.
  Future<String?> completeLesson(String lessonId) async {
    try {
      await _learningService.completeLesson(lessonId);
    } on ApiException catch (error) {
      return error.message;
    }
    await refreshProgress();
    return null;
  }

  /// Full lesson content (text, video or document link).
  Future<Lesson> fetchLesson(String lessonId) {
    return _courseService.getLesson(lessonId);
  }

  void reset() {
    courseId = '';
    courseTitle = '';
    sections = const [];
    lessonsBySection.clear();
    sectionErrors.clear();
    progress = null;
    isLoading = false;
    errorMessage = null;
    progressNotice = null;
    notifyListeners();
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/course_section.dart';
import 'package:flutter_lms/models/lesson.dart';
import 'package:flutter_lms/services/instructor_lesson_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class InstructorLessonProvider extends ChangeNotifier {
  InstructorLessonProvider(this._service);

  final InstructorLessonService _service;

  List<CourseSection> sections = const [];
  List<Lesson> lessons = const [];
  String? sectionsError;
  String? lessonsError;
  bool isLoadingSections = false;
  bool isLoadingLessons = false;
  bool isBusy = false;
  bool isUploading = false;
  double? uploadProgress;

  CancelToken? _uploadCancelToken;
  String? _currentSectionId;
  int _sectionsRequest = 0;
  int _lessonsRequest = 0;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadSections(String courseId) async {
    final request = ++_sectionsRequest;
    isLoadingSections = true;
    sectionsError = null;
    _notify();
    try {
      final result = await _service.getCourseSections(courseId);
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

  Future<void> loadLessons(String sectionId, {bool force = false}) async {
    if (isBusy && !force) return;
    _currentSectionId = sectionId;
    final request = ++_lessonsRequest;
    isLoadingLessons = true;
    lessonsError = null;
    _notify();
    try {
      final result = await _service.getSectionLessons(sectionId);
      if (_disposed || request != _lessonsRequest) return;
      lessons = result;
    } on ApiException catch (error) {
      if (_disposed || request != _lessonsRequest) return;
      lessonsError = error.message;
    } finally {
      if (!_disposed && request == _lessonsRequest) {
        isLoadingLessons = false;
        _notify();
      }
    }
  }

  Future<Lesson> fetchLesson(String lessonId) => _service.getLesson(lessonId);

  Future<String?> createLesson(String sectionId, Map<String, dynamic> body) {
    return _runMutation(() => _service.createLesson(sectionId, body));
  }

  Future<String?> updateLesson(
    String lessonId,
    Map<String, dynamic> changedFields,
  ) {
    if (changedFields.isEmpty) return Future.value(null);
    return _runMutation(() => _service.updateLesson(lessonId, changedFields));
  }

  Future<String?> setPublished(Lesson lesson, bool isPublished) {
    return updateLesson(lesson.id, {'isPublished': isPublished});
  }

  Future<String?> reorderLesson(String lessonId, int order) {
    return _runMutation(() => _service.reorderLesson(lessonId, order));
  }

  Future<String?> uploadVideo(String lessonId, String path, String fileName) {
    return _runUpload((token) {
      return _service.uploadVideo(
        lessonId,
        path,
        fileName,
        cancelToken: token,
        onSendProgress: _onUploadProgress,
      );
    });
  }

  Future<String?> uploadDocument(
    String lessonId,
    String path,
    String fileName,
  ) {
    return _runUpload((token) {
      return _service.uploadDocument(
        lessonId,
        path,
        fileName,
        cancelToken: token,
        onSendProgress: _onUploadProgress,
      );
    });
  }

  Future<String?> _runUpload(Future<void> Function(CancelToken token) upload) {
    if (isBusy || _disposed) {
      return Future.value('Please wait for the current action to finish.');
    }
    final token = CancelToken();
    _uploadCancelToken = token;
    isUploading = true;
    uploadProgress = 0;
    return _runMutation(() => upload(token)).whenComplete(() {
      if (_disposed) return;
      isUploading = false;
      uploadProgress = null;
      _uploadCancelToken = null;
      _notify();
    });
  }

  void _onUploadProgress(int sent, int total) {
    if (_disposed || total <= 0) return;
    uploadProgress = (sent / total).clamp(0, 1).toDouble();
    _notify();
  }

  void cancelUpload() {
    _uploadCancelToken?.cancel();
  }

  Future<String?> deleteVideo(String lessonId) {
    return _runMutation(() => _service.deleteVideo(lessonId));
  }

  Future<String?> deleteDocument(String lessonId) {
    return _runMutation(() => _service.deleteDocument(lessonId));
  }

  Future<String?> deleteLesson(String lessonId) {
    return _runMutation(() => _service.deleteLesson(lessonId));
  }

  Future<String?> _runMutation(Future<void> Function() action) async {
    if (_disposed) return null;
    if (isBusy) return 'Please wait for the current action to finish.';
    isBusy = true;
    _notify();
    try {
      await action();
      final sectionId = _currentSectionId;
      if (sectionId != null && !_disposed) {
        await loadLessons(sectionId, force: true);
      }
      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      if (!_disposed) {
        isBusy = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sectionsRequest++;
    _lessonsRequest++;
    _uploadCancelToken?.cancel();
    super.dispose();
  }
}

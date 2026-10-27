import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/course.dart';
import 'package:flutter_lms/models/course_category.dart';
import 'package:flutter_lms/services/course_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/app_config.dart';

class CourseCatalogProvider extends ChangeNotifier {
  CourseCatalogProvider(this._service);

  final CourseService _service;

  static const pageSize = AppConfig.defaultPageSize;

  List<CourseCategory> categories = [];
  List<Course> courses = [];
  String search = '';
  String? selectedCategoryId;
  String? selectedLevel;
  String? selectedLanguage;

  bool isLoading = false;
  bool isLoadingMore = false;
  bool isLoadingCategories = false;
  bool categoriesLoaded = false;
  String? categoriesError;
  String? errorMessage;
  String? loadMoreError;
  bool hasMore = false;

  int _page = 1;
  int _requestId = 0;
  int _categoryRequestId = 0;
  bool _initialized = false;
  bool _disposed = false;

  List<String> get availableLanguages {
    final languages = <String>{
      for (final course in courses)
        if (course.language.trim().isNotEmpty) course.language.trim(),
      ?selectedLanguage,
    }.toList();
    languages.sort();
    return languages;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await Future.wait([_loadCategories(), refresh()]);
  }

  Future<void> _loadCategories() async {
    final request = ++_categoryRequestId;
    isLoadingCategories = true;
    categoriesError = null;
    _notify();
    try {
      final result = await _service.getCategories();
      if (request != _categoryRequestId) return;
      categories = result.items;
      categoriesLoaded = true;
    } on ApiException catch (error) {
      if (request != _categoryRequestId) return;
      categoriesError = error.message;
    } finally {
      if (request == _categoryRequestId) {
        isLoadingCategories = false;
        _notify();
      }
    }
  }

  Future<void> retryCategories() => _loadCategories();

  void _clearForFilterChange() {
    _requestId++;
    courses = [];
    isLoadingMore = false;
    hasMore = false;
    _page = 1;
    loadMoreError = null;
    _notify();
  }

  Future<void> refresh() async {
    final request = ++_requestId;
    isLoading = true;
    isLoadingMore = false;
    errorMessage = null;
    loadMoreError = null;
    _notify();

    try {
      final result = await _service.browseCourses(
        page: 1,
        limit: pageSize,
        search: search,
        categoryId: selectedCategoryId,
        level: selectedLevel,
        language: selectedLanguage,
      );
      if (request != _requestId) return;
      courses = result.items;
      _page = result.page;
      hasMore = result.hasMore;
    } on ApiException catch (error) {
      if (request != _requestId) return;
      courses = [];
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
      final result = await _service.browseCourses(
        page: _page + 1,
        limit: pageSize,
        search: search,
        categoryId: selectedCategoryId,
        level: selectedLevel,
        language: selectedLanguage,
      );
      if (request == _requestId) {
        courses = [...courses, ...result.items];
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

  Future<void> setSearch(String value) {
    final next = value.trim();
    if (search == next) return Future.value();
    search = next;
    _clearForFilterChange();
    return refresh();
  }

  Future<void> selectCategory(String? categoryId) {
    if (selectedCategoryId == categoryId) return Future.value();
    selectedCategoryId = categoryId;
    _clearForFilterChange();
    return refresh();
  }

  Future<void> selectLevel(String? level) {
    if (selectedLevel == level) return Future.value();
    selectedLevel = level;
    _clearForFilterChange();
    return refresh();
  }

  Future<void> selectLanguage(String? language) {
    if (selectedLanguage == language) return Future.value();
    selectedLanguage = language;
    _clearForFilterChange();
    return refresh();
  }

  void reset() {
    _requestId++;
    _categoryRequestId++;
    _initialized = false;
    categories = [];
    courses = [];
    search = '';
    selectedCategoryId = null;
    selectedLevel = null;
    selectedLanguage = null;
    isLoading = false;
    isLoadingMore = false;
    isLoadingCategories = false;
    categoriesLoaded = false;
    categoriesError = null;
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
    _categoryRequestId++;
    super.dispose();
  }
}

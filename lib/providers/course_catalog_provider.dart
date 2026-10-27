import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/course.dart';
import 'package:flutter_lms/models/course_category.dart';
import 'package:flutter_lms/services/course_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class CourseCatalogProvider extends ChangeNotifier {
  CourseCatalogProvider(this._service);

  final CourseService _service;

  static const pageSize = 10;

  List<CourseCategory> categories = [];
  List<Course> courses = [];
  String search = '';
  String? selectedCategoryId;
  String? selectedLevel;

  bool isLoading = false; // first page or refresh
  bool isLoadingMore = false; // next pages
  String? errorMessage;
  String? loadMoreError;
  bool hasMore = false;

  int _page = 1;
  int _requestId = 0; // ignores answers that arrive after a newer request
  bool _initialized = false;

  /// Loads categories and the first page once.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await Future.wait([_loadCategories(), refresh()]);
  }

  Future<void> _loadCategories() async {
    try {
      final result = await _service.getCategories();
      categories = result.items;
    } on ApiException {
      categories = []; // filters are optional, so the list still works
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    final request = ++_requestId;
    isLoading = true;
    errorMessage = null;
    loadMoreError = null;
    notifyListeners();

    try {
      final result = await _service.browseCourses(
        page: 1,
        limit: pageSize,
        search: search,
        categoryId: selectedCategoryId,
        level: selectedLevel,
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
      final result = await _service.browseCourses(
        page: _page + 1,
        limit: pageSize,
        search: search,
        categoryId: selectedCategoryId,
        level: selectedLevel,
      );
      if (request == _requestId) {
        courses = [...courses, ...result.items];
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

  Future<void> setSearch(String value) {
    search = value.trim();
    return refresh();
  }

  Future<void> selectCategory(String? categoryId) {
    selectedCategoryId = categoryId;
    return refresh();
  }

  Future<void> selectLevel(String? level) {
    selectedLevel = level;
    return refresh();
  }

  void reset() {
    _requestId++;
    _initialized = false;
    categories = [];
    courses = [];
    search = '';
    selectedCategoryId = null;
    selectedLevel = null;
    isLoading = false;
    isLoadingMore = false;
    errorMessage = null;
    loadMoreError = null;
    hasMore = false;
    _page = 1;
    notifyListeners();
  }
}

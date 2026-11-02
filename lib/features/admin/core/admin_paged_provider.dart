import 'package:flutter/foundation.dart';
import 'package:flutter_lms/features/admin/core/admin_paged_data.dart';
import 'package:flutter_lms/utils/api_exception.dart';

typedef AdminPageLoader<T> = Future<AdminPagedData<T>> Function(
  int page,
  Map<String, String> filters,
);

class AdminPagedProvider<T> extends ChangeNotifier {
  AdminPagedProvider(this._loadPage);

  static const pageSize = 20;
  final AdminPageLoader<T> _loadPage;
  List<T> items = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isSubmitting = false;
  bool hasMore = false;
  String? errorMessage;
  String? loadMoreError;
  int currentPage = 1;
  int totalPages = 1;
  int total = 0;
  final Map<String, String> filters = {};
  bool _disposed = false;
  int _requestId = 0;
  bool _reloadAfterCurrentRequest = false;

  void notifySafely() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({bool refresh = false}) async {
    if (_disposed || isLoading || (isLoadingMore && !refresh)) return;
    final request = ++_requestId;
    isLoading = true;
    errorMessage = null;
    loadMoreError = null;
    if (refresh) {
      currentPage = 1;
      hasMore = false;
      isLoadingMore = false;
    }
    notifySafely();
    try {
      final result = await _loadPage(1, Map.unmodifiable(filters));
      if (_disposed || request != _requestId) return;
      items = result.items;
      currentPage = result.page;
      totalPages = result.totalPages;
      total = result.total;
      hasMore = result.hasMore;
    } on ApiException catch (error) {
      if (_disposed || request != _requestId) return;
      errorMessage = error.message;
      if (refresh) items = [];
    } catch (_) {
      if (_disposed || request != _requestId) return;
      errorMessage = 'Unable to load data. Please try again.';
      if (refresh) items = [];
    } finally {
      if (!_disposed && request == _requestId) {
        isLoading = false;
        notifySafely();
        if (_reloadAfterCurrentRequest) {
          _reloadAfterCurrentRequest = false;
          await load(refresh: true);
        }
      }
    }
  }

  Future<void> loadMore() async {
    if (_disposed || isLoading || isLoadingMore || !hasMore) return;
    final request = _requestId;
    isLoadingMore = true;
    loadMoreError = null;
    notifySafely();
    try {
      final result = await _loadPage(
        currentPage + 1,
        Map.unmodifiable(filters),
      );
      if (_disposed || request != _requestId) return;
      items = [...items, ...result.items];
      currentPage = result.page;
      totalPages = result.totalPages;
      total = result.total;
      hasMore = result.hasMore;
    } on ApiException catch (error) {
      if (!_disposed && request == _requestId) loadMoreError = error.message;
    } catch (_) {
      if (!_disposed && request == _requestId) {
        loadMoreError = 'Unable to load more items. Please try again.';
      }
    } finally {
      if (!_disposed && request == _requestId) {
        isLoadingMore = false;
        notifySafely();
        if (_reloadAfterCurrentRequest) {
          _reloadAfterCurrentRequest = false;
          await load(refresh: true);
        }
      }
    }
  }

  Future<void> applyFilters(Map<String, String> values) async {
    if (_disposed) return;
    filters
      ..clear()
      ..addEntries(
        values.entries.where((entry) => entry.value.trim().isNotEmpty),
      );
    if (isLoading || isLoadingMore) {
      _reloadAfterCurrentRequest = true;
      return;
    }
    await load(refresh: true);
  }

  Future<void> clearFilters() => applyFilters(const {});

  Future<R> runAction<R>(Future<R> Function() action) async {
    if (_disposed || isSubmitting) {
      throw const ApiException(
        message: 'Please wait for the current action to finish.',
      );
    }
    isSubmitting = true;
    notifySafely();
    try {
      return await action();
    } finally {
      if (!_disposed) {
        isSubmitting = false;
        notifySafely();
      }
    }
  }

  void replaceItem(bool Function(T) test, T replacement) {
    if (_disposed) return;
    final index = items.indexWhere(test);
    if (index < 0) return;
    items = [...items]..[index] = replacement;
    notifySafely();
  }

  void removeItem(bool Function(T) test) {
    if (_disposed) return;
    items = items.where((item) => !test(item)).toList();
    notifySafely();
  }

  void reset() {
    _requestId++;
    items = [];
    filters.clear();
    isLoading = false;
    isLoadingMore = false;
    isSubmitting = false;
    hasMore = false;
    errorMessage = null;
    loadMoreError = null;
    currentPage = 1;
    totalPages = 1;
    total = 0;
    _reloadAfterCurrentRequest = false;
    notifySafely();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    super.dispose();
  }
}

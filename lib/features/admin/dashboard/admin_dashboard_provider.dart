import 'package:flutter/foundation.dart';
import 'package:flutter_lms/features/admin/dashboard/admin_dashboard_service.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class AdminDashboardProvider extends ChangeNotifier {
  AdminDashboardProvider(this._service);
  final AdminDashboardService _service;

  AdminDashboardSummary? summary;
  bool isLoading = false;
  String? errorMessage;
  bool _disposed = false;

  Future<void> load({bool refresh = false}) async {
    if (_disposed || isLoading || (summary != null && !refresh)) return;
    isLoading = true;
    errorMessage = null;
    _notify();
    try {
      summary = await _service.load();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Unable to load the admin dashboard. Please try again.';
    } finally {
      isLoading = false;
      _notify();
    }
  }

  void reset() {
    summary = null;
    errorMessage = null;
    isLoading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

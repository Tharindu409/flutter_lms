import 'package:flutter_lms/features/admin/core/admin_paged_provider.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/features/admin/users/admin_users_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class AdminUsersProvider extends AdminPagedProvider<AdminUser> {
  AdminUsersProvider(this.service)
    : super(
        (page, filters) => service.list(
          page: page,
          search: filters['search'] ?? '',
          role: filters['role'] ?? '',
          status: filters['status'] ?? '',
        ),
      );

  final AdminUsersService service;
  AdminUser? selectedUser;

  Future<void> applyUserFilters({
    String search = '',
    String role = '',
    String status = '',
  }) => super.applyFilters({'search': search, 'role': role, 'status': status});

  Future<AdminUser> loadDetails(String userId) async {
    try {
      selectedUser = await service.details(userId);
      notifySafely();
      return selectedUser!;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(message: 'Unable to load this user.');
    }
  }

  Future<void> setUserStatus(String userId, String status) async {
    final updated = await runAction(() => service.setStatus(userId, status));
    replaceItem((user) => user.id == userId, updated);
    if (selectedUser?.id == userId) selectedUser = updated;
    notifySafely();
  }

  void setSelectedUser(AdminUser? value) {
    selectedUser = value;
    notifySafely();
  }

  @override
  void reset() {
    selectedUser = null;
    super.reset();
  }
}

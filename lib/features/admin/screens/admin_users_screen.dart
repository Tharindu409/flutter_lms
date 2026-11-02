import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/features/admin/users/admin_users_provider.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/widgets/confirm_dialog.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:provider/provider.dart';

import 'admin_screen_components.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, required this.onOpenMore});

  final VoidCallback onOpenMore;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _role = '';
  String _status = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminUsersProvider>().load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _filter() => context.read<AdminUsersProvider>().applyUserFilters(
    search: _search.text.trim(),
    role: _role,
    status: _status,
  );

  Future<void> _showDetails(AdminUser user) async {
    final provider = context.read<AdminUsersProvider>();
    await showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider<AdminUsersProvider>.value(
        value: provider,
        child: _AdminUserDetailsDialog(userId: user.id),
      ),
    );
  }

  Future<void> _changeStatus(AdminUser user) async {
    final next = user.status == 'SUSPENDED' ? 'ACTIVE' : 'SUSPENDED';
    final accepted = await showConfirmDialog(
      context,
      title: next == 'SUSPENDED' ? 'Suspend user?' : 'Reactivate user?',
      message: next == 'SUSPENDED'
          ? 'The user will be signed out and must sign in again after reactivation.'
          : 'The user must sign in again to start a new session.',
      confirmLabel: next == 'SUSPENDED' ? 'Suspend' : 'Reactivate',
    );
    if (!mounted || !accepted) return;
    try {
      await context.read<AdminUsersProvider>().setUserStatus(user.id, next);
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminUsersProvider>(
      builder: (context, provider, _) => Column(
        children: [
          AdminHeader(
            title: 'Users',
            subtitle: 'Manage accounts and access',
            action: adminMoreButton(widget.onOpenMore),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 400),
                  () => _filter(),
                );
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search name or email',
              ),
            ),
          ),
          AdminFilterRow(
            value: _role,
            values: const ['', 'STUDENT', 'INSTRUCTOR', 'ADMIN'],
            labels: const ['All roles', 'Student', 'Instructor', 'Admin'],
            onChanged: (value) {
              _role = value;
              _filter();
            },
          ),
          AdminFilterRow(
            value: _status,
            values: const ['', 'ACTIVE', 'INACTIVE', 'SUSPENDED'],
            labels: const ['All status', 'Active', 'Inactive', 'Suspended'],
            onChanged: (value) {
              _status = value;
              _filter();
            },
          ),
          Expanded(
            child: adminPagedBody<AdminUser>(
              provider: provider,
              title: 'No users found',
              onRefresh: () => provider.load(refresh: true),
              itemBuilder: (user) {
                final ownAccount =
                    user.id == context.read<AuthProvider>().user?.id;
                return Card(
                  child: ListTile(
                    onTap: () => _showDetails(user),
                    title: Text(
                      user.fullName.isEmpty ? user.email : user.fullName,
                    ),
                    subtitle: Text('${user.email} · ${user.role}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AdminStatusBadge(value: user.status),
                        if (!ownAccount)
                          PopupMenuButton<String>(
                            enabled: !provider.isSubmitting,
                            onSelected: (_) => _changeStatus(user),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: user.status == 'SUSPENDED'
                                    ? 'ACTIVE'
                                    : 'SUSPENDED',
                                child: Text(
                                  user.status == 'SUSPENDED'
                                      ? 'Reactivate'
                                      : 'Suspend',
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminUserDetailsDialog extends StatefulWidget {
  const _AdminUserDetailsDialog({required this.userId});
  final String userId;

  @override
  State<_AdminUserDetailsDialog> createState() =>
      _AdminUserDetailsDialogState();
}

class _AdminUserDetailsDialogState extends State<_AdminUserDetailsDialog> {
  late Future<AdminUser> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AdminUsersProvider>().loadDetails(widget.userId);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('User details'),
    content: SizedBox(
      width: 360,
      child: FutureBuilder<AdminUser>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: LoadingView(message: 'Loading user details...'),
            );
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is ApiException
                ? error.message
                : 'Unable to load this user. Please try again.';
            return ErrorView(
              message: message,
              onRetry: () => setState(
                () => _future = context.read<AdminUsersProvider>().loadDetails(
                  widget.userId,
                ),
              ),
            );
          }
          final user = snapshot.data;
          if (user == null) {
            return ErrorView(
              message: 'User details are unavailable.',
              onRetry: () => setState(
                () => _future = context.read<AdminUsersProvider>().loadDetails(
                  widget.userId,
                ),
              ),
            );
          }
          return Text(
            'Name: ${user.fullName}\nEmail: ${user.email}'
            '\nRole: ${user.role}\nStatus: ${user.status}',
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}

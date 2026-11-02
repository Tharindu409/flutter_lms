import 'package:flutter/material.dart';
import 'package:flutter_lms/features/admin/dashboard/admin_dashboard_provider.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/widgets/confirm_dialog.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:provider/provider.dart';

import 'admin_screen_components.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.onOpenMore});

  final VoidCallback onOpenMore;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log out',
    );
    if (!mounted || !confirmed) return;
    try {
      await context.read<AuthProvider>().logout();
    } on ApiException {
      // The session is cleared in AuthProvider.logout even when the API fails.
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminDashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'More',
            onPressed: widget.onOpenMore,
            icon: const Icon(Icons.more_vert),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Consumer<AdminDashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.summary == null) {
            return const LoadingView(message: 'Loading admin dashboard...');
          }
          if (provider.errorMessage != null && provider.summary == null) {
            return RefreshIndicator(
              onRefresh: () => provider.load(refresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 320,
                    child: ErrorView(
                      message: provider.errorMessage!,
                      onRetry: () => provider.load(refresh: true),
                    ),
                  ),
                ],
              ),
            );
          }
          final summary = provider.summary;
          if (summary == null) {
            return RefreshIndicator(
              onRefresh: () => provider.load(refresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 320,
                    child: ErrorView(
                      message: 'Admin dashboard data is unavailable.',
                      onRetry: () => provider.load(refresh: true),
                    ),
                  ),
                ],
              ),
            );
          }

          final metrics = <(String, int?, IconData)>[
            ('Students', summary.totalStudents, Icons.school_outlined),
            ('Instructors', summary.totalInstructors, Icons.person_outline),
            ('Active users', summary.activeUsers, Icons.verified_user_outlined),
            ('Published courses', summary.publishedCourses, Icons.menu_book),
            (
              'Non-cancelled enrollments',
              summary.nonCancelledEnrollments,
              Icons.groups_outlined,
            ),
            (
              'Completed enrollments',
              summary.completedEnrollments,
              Icons.task_alt,
            ),
          ];
          return RefreshIndicator(
            onRefresh: () => provider.load(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Platform overview',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(color: Colors.white, fontSize: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A snapshot of activity across your learning platform.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 600 ? 3 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: metrics.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: columns == 2 ? 1 : 1.35,
                      ),
                      itemBuilder: (context, index) {
                        final (label, value, icon) = metrics[index];
                        return AdminMetricCard(
                          label: label,
                          value: value?.toString() ?? '--',
                          icon: icon,
                          index: index,
                        );
                      },
                    );
                  },
                ),
                if (provider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextButton.icon(
                      onPressed: () => provider.load(refresh: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh failed. Retry'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

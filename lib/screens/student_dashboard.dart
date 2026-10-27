import 'package:flutter/material.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/profile_provider.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:flutter_lms/widgets/app_logo.dart';
import 'package:flutter_lms/widgets/confirm_dialog.dart';
import 'package:provider/provider.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  static const _quickTasks = [
    _DashboardAction(
      label: 'Join Online Class',
      icon: Icons.videocam_outlined,
      color: AppTheme.primary,
    ),
    _DashboardAction(
      label: 'Submit Assignment',
      icon: Icons.assignment_outlined,
      color: AppTheme.secondary,
    ),
    _DashboardAction(
      label: 'Check Grades',
      icon: Icons.bar_chart_rounded,
      color: AppTheme.tertiary,
    ),
    _DashboardAction(
      label: 'Contact Teacher',
      icon: Icons.mail_outline_rounded,
      color: AppTheme.primary,
    ),
  ];

  static const _quickAccess = [
    _DashboardAction(
      label: 'Courses',
      icon: Icons.school_outlined,
      color: AppTheme.primary,
    ),
    _DashboardAction(
      label: 'My Courses',
      icon: Icons.menu_book_outlined,
      color: AppTheme.secondary,
    ),
    _DashboardAction(
      label: 'Grades',
      icon: Icons.show_chart_rounded,
      color: AppTheme.tertiary,
    ),
    _DashboardAction(
      label: 'Resources',
      icon: Icons.menu_book_outlined,
      color: AppTheme.secondary,
    ),
  ];

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
    );
    if (!context.mounted || !confirmed) return;

    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    try {
      await auth.logout();
    } on ApiException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
      return;
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
      return;
    }
    if (!context.mounted) return;
    profile.reset();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogo(size: 34),
            Card(
              child: ListTile(
                leading: const Icon(Icons.travel_explore),
                title: const Text('Browse courses'),
                subtitle: const Text('Find a course and start learning'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, AppRoutes.courses),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(width: 9),
            Text(
              'Flutter LMS',
              style: textTheme.titleMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _showComingSoon(context, 'Notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 16),
            child: PopupMenuButton<String>(
              tooltip: 'Account menu',
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.pushNamed(context, AppRoutes.profile);
                } else if (value == 'logout') {
                  _logout(context);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.account_circle_outlined, size: 19),
                      SizedBox(width: 10),
                      Text('Profile'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 19),
                      SizedBox(width: 10),
                      Text('Log out'),
                    ],
                  ),
                ),
              ],
              child: const CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFFEDE5FF),
                child: Text(
                  'ST',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Text(
                  'Hello, Student!',
                  style: textTheme.titleLarge?.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 7),
                    Text(_currentDate(), style: textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 18),
                const _SemesterProgressCard(),
                const SizedBox(height: 22),
                Text('Quick Tasks', style: textTheme.titleMedium),
                const SizedBox(height: 10),
                _ActionGrid(
                  actions: _quickTasks,
                  onTap: (action) => _showComingSoon(context, action.label),
                  filled: true,
                ),
                const SizedBox(height: 22),
                Text('Quick Access', style: textTheme.titleMedium),
                const SizedBox(height: 10),
                _ActionGrid(
                  actions: _quickAccess,
                  onTap: (action) {
                    if (action.label == 'Courses') {
                      Navigator.pushNamed(context, AppRoutes.courses);
                    } else if (action.label == 'My Courses') {
                      Navigator.pushNamed(context, AppRoutes.myCourses);
                    } else {
                      _showComingSoon(context, action.label);
                    }
                  },
                  filled: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _currentDate() {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    return '${weekdays[now.weekday - 1]}, $day ${months[now.month - 1]} '
        '${now.year}';
  }
}

class _SemesterProgressCard extends StatelessWidget {
  const _SemesterProgressCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.loginHeaderGradient,
        ),
        borderRadius: AppTheme.largeRadius,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep learning',
                  style: textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your enrolled courses are ready when you are.',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 13),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.myCourses),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('View my courses'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.school_rounded, color: Colors.white, size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final List<_DashboardAction> actions;
  final ValueChanged<_DashboardAction> onTap;
  final bool filled;

  const _ActionGrid({
    required this.actions,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 76,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _ActionTile(
          action: action,
          filled: filled,
          onTap: () => onTap(action),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final _DashboardAction action;
  final bool filled;
  final VoidCallback onTap;

  const _ActionTile({
    required this.action,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : AppTheme.textPrimary;

    return Material(
      color: filled ? action.color : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: filled ? null : Border.all(color: const Color(0xFFEFEAF5)),
            boxShadow: filled
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x080F082B),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.white.withValues(alpha: 0.2)
                      : action.color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  action.icon,
                  size: 19,
                  color: filled ? Colors.white : action.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardAction {
  final String label;
  final IconData icon;
  final Color color;

  const _DashboardAction({
    required this.label,
    required this.icon,
    required this.color,
  });
}

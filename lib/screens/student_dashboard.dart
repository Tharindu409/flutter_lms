import 'package:flutter/material.dart';

import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:flutter_lms/widgets/app_logo.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  static const _quickTasks = [
    _DashboardAction(
      label: 'Join Online Class',
      icon: Icons.videocam_outlined,
      color: Color(0xFF3269E9),
    ),
    _DashboardAction(
      label: 'Submit Assignment',
      icon: Icons.assignment_outlined,
      color: Color(0xFF18A85A),
    ),
    _DashboardAction(
      label: 'Check Grades',
      icon: Icons.bar_chart_rounded,
      color: Color(0xFFE58A00),
    ),
    _DashboardAction(
      label: 'Contact Teacher',
      icon: Icons.mail_outline_rounded,
      color: Color(0xFF9638DB),
    ),
  ];

  static const _quickAccess = [
    _DashboardAction(
      label: 'Courses',
      icon: Icons.school_outlined,
      color: Color(0xFF9638DB),
    ),
    _DashboardAction(
      label: 'Assignments',
      icon: Icons.description_outlined,
      color: Color(0xFF3981E8),
    ),
    _DashboardAction(
      label: 'Grades',
      icon: Icons.show_chart_rounded,
      color: Color(0xFF28A875),
    ),
    _DashboardAction(
      label: 'Resources',
      icon: Icons.menu_book_outlined,
      color: Color(0xFFE6A41B),
    ),
  ];

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }

  void _logout(BuildContext context) {
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
                if (value == 'logout') _logout(context);
              },
              itemBuilder: (context) => const [
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
                const SizedBox(height: 3),
                Text(_currentDate(), style: textTheme.bodySmall),
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
                  onTap: (action) => _showComingSoon(context, action.label),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB23BE4), Color(0xFF8129D2), Color(0xFF6335CF)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26812AD2),
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
                  'Semester Progress',
                  style: textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'You’re doing great!',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  '68%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '8 weeks remaining',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
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
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 0.68,
                    strokeWidth: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const Text(
                  '68%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
        mainAxisExtent: 68,
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
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.white.withValues(alpha: 0.2)
                      : action.color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
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

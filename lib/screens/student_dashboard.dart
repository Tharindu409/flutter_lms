import 'package:flutter/material.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/my_courses_provider.dart';
import 'package:flutter_lms/providers/notification_provider.dart';
import 'package:flutter_lms/providers/profile_provider.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:flutter_lms/widgets/app_logo.dart';
import 'package:flutter_lms/widgets/confirm_dialog.dart';
import 'package:flutter_lms/widgets/dashboard_widgets.dart';
import 'package:flutter_lms/widgets/section_header.dart';
import 'package:provider/provider.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool _started = false;
  bool _showCards = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final courses = context.read<MyCoursesProvider>();
      if (courses.enrollments.isEmpty && !courses.isLoading) {
        courses.refresh();
      }
      context.read<NotificationProvider>().refreshUnreadCount();
      setState(() => _showCards = true);
    });
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([
      context.read<MyCoursesProvider>().refresh(),
      context.read<NotificationProvider>().refreshUnreadCount(),
    ]);
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log out',
    );
    if (!context.mounted || !confirmed) return;

    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    try {
      await auth.logout();
    } on ApiException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
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
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 400 ? 16.0 : 24.0;
    final user = context.watch<AuthProvider>().user;
    final name = user?.firstName.trim().isNotEmpty == true
        ? user!.firstName.trim()
        : 'Student';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DashboardHeader(
                          firstName: name,
                          imageUrl: user?.profileImageUrl,
                          initials: user?.initials ?? 'S',
                          onProfile: () =>
                              Navigator.pushNamed(context, AppRoutes.profile),
                          onLogout: () => _logout(context),
                        ),
                        const SizedBox(height: 24),
                        AnimatedOpacity(
                          opacity: _showCards ? 1 : 0,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _KeepLearningCard(
                                onBrowse: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.courses,
                                ),
                                onMyCourses: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.myCourses,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const SectionHeader(
                                title: 'Your learning',
                                subtitle: 'Pick up where you left off.',
                              ),
                              const SizedBox(height: 12),
                              _ActionGrid(
                                availableWidth:
                                    constraints.maxWidth -
                                    horizontalPadding * 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.firstName,
    required this.imageUrl,
    required this.initials,
    required this.onProfile,
    required this.onLogout,
  });

  final String firstName;
  final String? imageUrl;
  final String initials;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x120F082B),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const AppLogo(size: 38),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Flutter LMS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Consumer<NotificationProvider>(
              builder: (context, notifications, _) => IconButton(
                tooltip: 'Notifications',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.notifications),
                icon: Badge(
                  isLabelVisible:
                      notifications.unreadCount != null &&
                      notifications.unreadCount! > 0,
                  label: Text(
                    notifications.unreadCount != null &&
                            notifications.unreadCount! > 99
                        ? '99+'
                        : '${notifications.unreadCount ?? 0}',
                  ),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Account menu',
              onSelected: (value) {
                if (value == 'profile') onProfile();
                if (value == 'logout') onLogout();
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
              child: _StudentAvatar(imageUrl: imageUrl, initials: initials),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Hello, $firstName',
          style: textTheme.headlineSmall?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text('Ready to make progress today?', style: textTheme.bodyMedium),
      ],
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({required this.imageUrl, required this.initials});

  final String? imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: 21,
      backgroundColor: const Color(0xFFEDE5FF),
      child: Text(
        initials,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _KeepLearningCard extends StatelessWidget {
  const _KeepLearningCard({required this.onBrowse, required this.onMyCourses});

  final VoidCallback onBrowse;
  final VoidCallback onMyCourses;

  @override
  Widget build(BuildContext context) {
    return Consumer<MyCoursesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.enrollments.isEmpty) {
          return const DashboardSummarySkeleton();
        }
        if (provider.errorMessage != null && provider.enrollments.isEmpty) {
          return _SummaryMessageCard(
            icon: Icons.cloud_off_outlined,
            title: 'Your courses are temporarily unavailable',
            message: 'Pull down to retry loading your learning summary.',
            actionLabel: 'Retry',
            onAction: provider.refresh,
          );
        }
        if (provider.enrollments.isEmpty) {
          return _SummaryMessageCard(
            icon: Icons.auto_stories_outlined,
            title: 'Your learning journey starts here',
            message:
                'Browse courses and your enrolled courses will appear here.',
            actionLabel: 'Browse courses',
            onAction: onBrowse,
          );
        }

        final enrollment = provider.enrollments.first;
        final course = enrollment.course;
        final isCompleted = provider.status == MyCoursesProvider.completed;
        final countLabel = isCompleted ? 'Completed shown' : 'Active shown';
        final progress = enrollment.progressPercentage;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.loginHeaderGradient,
            ),
            borderRadius: AppTheme.largeRadius,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCompleted ? 'Nice work' : 'Keep learning',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                isCompleted
                    ? 'Your completed courses are ready to revisit.'
                    : 'Pick up where you left off.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.white.withValues(alpha: 0.84)),
              ),
              const SizedBox(height: 16),
              SummaryStatCard(
                label: countLabel,
                value: '${provider.enrollments.length}',
                icon: isCompleted
                    ? Icons.check_circle_outline
                    : Icons.school_outlined,
              ),
              if (course != null) ...[
                const SizedBox(height: 16),
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Progress: $progress%',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onMyCourses,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('View my courses'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryMessageCard extends StatelessWidget {
  const _SummaryMessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary, size: 28),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.availableWidth});

  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final columns = (availableWidth / 190).floor().clamp(2, 4);
    final actions = [
      _Action(
        label: 'Courses',
        icon: Icons.school_outlined,
        color: AppTheme.primary,
        route: AppRoutes.courses,
      ),
      _Action(
        label: 'My Courses',
        icon: Icons.menu_book_outlined,
        color: AppTheme.secondary,
        route: AppRoutes.myCourses,
      ),
      _Action(
        label: 'Submit Assignment',
        icon: Icons.assignment_outlined,
        color: AppTheme.tertiary,
        route: AppRoutes.assignments,
      ),
      _Action(
        label: 'Notifications',
        icon: Icons.notifications_none_rounded,
        color: AppTheme.tertiary,
        route: AppRoutes.notifications,
      ),
      _Action(
        label: 'Profile',
        icon: Icons.account_circle_outlined,
        color: AppTheme.primary,
        route: AppRoutes.profile,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 112,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return DashboardActionCard(
          label: action.label,
          icon: action.icon,
          accentColor: action.color,
          onTap: () => Navigator.pushNamed(context, action.route),
        );
      },
    );
  }
}

class _Action {
  const _Action({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String route;
}

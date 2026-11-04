import 'package:flutter/material.dart';
import 'package:flutter_lms/models/dashboard_models.dart';
import 'package:flutter_lms/models/instructor_summary.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/instructor_dashboard_provider.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:flutter_lms/widgets/dashboard_widgets.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:provider/provider.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InstructorDashboardProvider>().load();
    });
  }

  List<DashboardStat> _stats(InstructorSummary s) => [
    DashboardStat(
      label: 'Total courses',
      value: s.totalCourses?.toString() ?? '--',
      icon: Icons.menu_book_outlined,
      color: AppTheme.primary,
    ),
    DashboardStat(
      label: 'Enrollments',
      value: '${s.totalEnrollments}',
      icon: Icons.groups_outlined,
      color: const Color(0xFF171522),
    ),
    DashboardStat(
      label: 'To review',
      value: '${s.pendingSubmissions}',
      icon: Icons.assignment_late_outlined,
      color: const Color(0xFF6D42D8),
    ),
    DashboardStat(
      label: 'Published',
      value: '${s.publishedCourses}',
      icon: Icons.public,
      color: const Color(0xFF312A40),
    ),
    DashboardStat(
      label: 'Drafts',
      value: '${s.draftCourses}',
      icon: Icons.edit_note,
      color: const Color(0xFF777184),
    ),
    DashboardStat(
      label: 'Archived',
      value: '${s.archivedCourses}',
      icon: Icons.archive_outlined,
      color: const Color(0xFF777184),
    ),
    DashboardStat(
      label: 'Avg. rating',
      value: s.averageRating.toStringAsFixed(1),
      icon: Icons.star_outline,
      color: const Color(0xFF6D42D8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().role != 'INSTRUCTOR') {
      return Scaffold(
        appBar: AppBar(title: const Text('Instructor Dashboard')),
        body: const Center(child: Text('You do not have access to this page')),
      );
    }
    final name = context.watch<AuthProvider>().user?.firstName;

    return Consumer<InstructorDashboardProvider>(
      builder: (context, dashboard, _) {
        final summary = dashboard.summary;
        final loading =
            dashboard.isLoading ||
            (summary == null && dashboard.errorMessage == null);

        return DashboardScaffold(
          title: 'Instructor Dashboard',
          onRefresh: dashboard.load,
          children: [
            _InstructorWelcomeCard(
              name: name?.trim().isNotEmpty == true
                  ? name!.trim()
                  : 'Instructor',
              onManageCourses: () =>
                  Navigator.pushNamed(context, AppRoutes.instructorCourses),
            ),
            const SizedBox(height: 28),
            const _DashboardSectionHeading(
              title: 'Teaching overview',
              subtitle: 'A quick look at your courses and learners.',
            ),
            const SizedBox(height: 14),
            if (summary != null)
              DashboardGrid(
                children: _stats(summary)
                    .map((stat) => _InstructorMetricCard(stat: stat))
                    .toList(),
              )
            else if (loading)
              const SizedBox(
                height: 200,
                child: LoadingView(message: 'Loading dashboard...'),
              )
            else
              ErrorView(
                message:
                    dashboard.errorMessage ?? 'Could not load the dashboard.',
                onRetry: dashboard.load,
              ),
          ],
        );
      },
    );
  }
}

class _InstructorWelcomeCard extends StatelessWidget {
  const _InstructorWelcomeCard({
    required this.name,
    required this.onManageCourses,
  });

  final String name;
  final VoidCallback onManageCourses;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F2BB4), Color(0xFF7852E8)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x294F2BB4),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -46,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 24,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        color: Colors.white,
                        size: 15,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'INSTRUCTOR WORKSPACE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome back,\n$name',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1.12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Keep your courses moving and your learners inspired.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onManageCourses,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Manage courses'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF452398),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

class _DashboardSectionHeading extends StatelessWidget {
  const _DashboardSectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF171522),
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: const Color(0xFF777184), fontSize: 12),
        ),
      ],
    );
  }
}

class _InstructorMetricCard extends StatelessWidget {
  const _InstructorMetricCard({required this.stat});

  final DashboardStat stat;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFECEAF1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: stat.color.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(stat.icon, color: stat.color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              stat.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF171522),
                fontSize: 25,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.7,
              ),
            ),
            Text(
              stat.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF777184),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_lms/models/dashboard_models.dart';
import 'package:flutter_lms/models/instructor_summary.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/instructor_dashboard_provider.dart';
import 'package:flutter_lms/utils/app_routes.dart';
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
      value: '${s.totalCourses}',
      icon: Icons.menu_book_outlined,
      color: Colors.indigo,
    ),
    DashboardStat(
      label: 'Published',
      value: '${s.publishedCourses}',
      icon: Icons.public,
      color: Colors.green,
    ),
    DashboardStat(
      label: 'Drafts',
      value: '${s.draftCourses}',
      icon: Icons.edit_note,
      color: Colors.orange,
    ),
    DashboardStat(
      label: 'Archived',
      value: '${s.archivedCourses}',
      icon: Icons.archive_outlined,
      color: Colors.blueGrey,
    ),
    DashboardStat(
      label: 'Enrollments',
      value: '${s.totalEnrollments}',
      icon: Icons.groups_outlined,
      color: Colors.blue,
    ),
    DashboardStat(
      label: 'To review',
      value: '${s.pendingSubmissions}',
      icon: Icons.assignment_late_outlined,
      color: Colors.red,
    ),
    DashboardStat(
      label: 'Avg. rating',
      value: s.averageRating.toStringAsFixed(1),
      icon: Icons.star_outline,
      color: Colors.amber,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (index) {
              if (index == 1) {
                Navigator.pushNamed(context, AppRoutes.instructorCourses);
              } else if (index == 2) {
                Navigator.pushNamed(context, AppRoutes.profile);
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                label: 'My Courses',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
          children: [
            GreetingHeader(
              greeting: 'Hello, ${name ?? 'Instructor'}',
              subtitle: 'Manage your courses and learners.',
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.instructorCourses),
              icon: const Icon(Icons.play_lesson_outlined),
              label: const Text('Manage my courses'),
            ),
            const SizedBox(height: 20),
            if (summary != null)
              DashboardGrid(
                children: _stats(summary)
                    .map((s) => StatCard(stat: s))
                    .toList(),
              )
            else if (loading)
              const SizedBox(
                height: 200,
                child: LoadingView(message: 'Loading dashboard...'),
              )
            else
              SizedBox(
                height: 200,
                child: ErrorView(
                  message:
                      dashboard.errorMessage ?? 'Could not load the dashboard.',
                  onRetry: dashboard.load,
                ),
              ),
          ],
        );
      },
    );
  }
}

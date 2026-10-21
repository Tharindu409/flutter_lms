import 'package:flutter/material.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/state_views.dart';
import '../dashboard/data/dummy_dashboard_data.dart';
import '../dashboard/widgets/dashboard_widgets.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const activity = DummyDashboardData.studentActivity;

    return DashboardScaffold(
      title: 'Student Dashboard',
      children: [
        const GreetingHeader(
          greeting: 'Hello, Student',
          subtitle: 'Ready to continue learning?',
        ),
        const SizedBox(height: 20),
        DashboardGrid(
          children: DummyDashboardData.studentStats
              .map((s) => StatCard(stat: s))
              .toList(),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Continue learning'),
        const SizedBox(height: 12),
        ...DummyDashboardData.continueLearning
            .map((c) => CourseProgressCard(course: c)),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Recent activity'),
        const SizedBox(height: 12),
        if (activity.isEmpty)
          const EmptyView(
            title: 'No activity yet',
            message: 'Start a lesson to see your activity here.',
          )
        else
          ...activity.map((a) => ActivityTile(item: a)),
      ],
    );
  }
}
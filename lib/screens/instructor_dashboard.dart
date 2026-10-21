import 'package:flutter/material.dart';
import 'package:flutter_lms/services/dummy_dashboard_data.dart';
import 'package:flutter_lms/widgets/dashboard_widgets.dart';
import 'package:flutter_lms/widgets/section_header.dart';

class InstructorDashboard extends StatelessWidget {
  const InstructorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'Instructor Dashboard',
      children: [
        const GreetingHeader(
          greeting: 'Hello, Instructor',
          subtitle: 'Manage your courses and learners.',
        ),
        const SizedBox(height: 20),
        DashboardGrid(
          children: DummyDashboardData.instructorStats
              .map((s) => StatCard(stat: s))
              .toList(),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Quick actions'),
        const SizedBox(height: 12),
        DashboardGrid(
          itemHeight: 88,
          children: DummyDashboardData.instructorActions
              .map((a) => QuickActionCard(action: a))
              .toList(),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Recent activity'),
        const SizedBox(height: 12),
        ...DummyDashboardData.instructorActivity.map(
          (a) => ActivityTile(item: a),
        ),
      ],
    );
  }
}

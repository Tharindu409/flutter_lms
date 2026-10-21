import 'package:flutter/material.dart';
import 'package:flutter_lms/services/dummy_dashboard_data.dart';
import 'package:flutter_lms/widgets/dashboard_widgets.dart';
import 'package:flutter_lms/widgets/section_header.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'Admin Dashboard',
      children: [
        const GreetingHeader(
          greeting: 'Hello, Admin',
          subtitle: 'Platform overview and management.',
        ),
        const SizedBox(height: 20),
        DashboardGrid(
          children: DummyDashboardData.adminStats
              .map((s) => StatCard(stat: s))
              .toList(),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Management'),
        const SizedBox(height: 12),
        DashboardGrid(
          itemHeight: 88,
          children: DummyDashboardData.adminActions
              .map((a) => QuickActionCard(action: a))
              .toList(),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Recent activity'),
        const SizedBox(height: 12),
        ...DummyDashboardData.adminActivity.map((a) => ActivityTile(item: a)),
      ],
    );
  }
}

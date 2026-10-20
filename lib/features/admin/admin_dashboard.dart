import 'package:flutter/material.dart';
import '../../shared/widgets/placeholder_dashboard.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderDashboard(
      title: 'Admin Dashboard',
      icon: Icons.admin_panel_settings,
    );
  }
}
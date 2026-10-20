import 'package:flutter/material.dart';
import '../../shared/widgets/placeholder_dashboard.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderDashboard(
      title: 'Student Dashboard',
      icon: Icons.menu_book,
    );
  }
}
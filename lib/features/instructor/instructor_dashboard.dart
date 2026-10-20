import 'package:flutter/material.dart';
import '../../shared/widgets/placeholder_dashboard.dart';

class InstructorDashboard extends StatelessWidget {
  const InstructorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderDashboard(
      title: 'Instructor Dashboard',
      icon: Icons.cast_for_education,
    );
  }
}
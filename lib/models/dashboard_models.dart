import 'package:flutter/material.dart';

class DashboardStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class CourseProgress {
  final String title;
  final String instructor;
  final double progress; // 0.0 to 1.0

  const CourseProgress({
    required this.title,
    required this.instructor,
    required this.progress,
  });
}

class QuickAction {
  final String label;
  final IconData icon;

  const QuickAction({required this.label, required this.icon});
}

class ActivityItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

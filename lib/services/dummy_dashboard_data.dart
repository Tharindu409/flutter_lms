import 'package:flutter/material.dart';
import 'package:flutter_lms/models/dashboard_models.dart';

class DummyDashboardData {
  // ---------- Student ----------
  static const studentStats = [
    DashboardStat(
      label: 'Enrolled',
      value: '5',
      icon: Icons.school_outlined,
      color: Colors.indigo,
    ),
    DashboardStat(
      label: 'In progress',
      value: '3',
      icon: Icons.play_circle_outline,
      color: Colors.blue,
    ),
    DashboardStat(
      label: 'Completed',
      value: '2',
      icon: Icons.check_circle_outline,
      color: Colors.green,
    ),
    DashboardStat(
      label: 'Pending tasks',
      value: '4',
      icon: Icons.assignment_outlined,
      color: Colors.orange,
    ),
  ];

  static const continueLearning = [
    CourseProgress(
      title: 'Flutter for Beginners',
      instructor: 'Instructor A',
      progress: 0.65,
    ),
    CourseProgress(
      title: 'Dart Fundamentals',
      instructor: 'Instructor B',
      progress: 0.3,
    ),
  ];

  static const studentActivity = [
    ActivityItem(
      title: 'Lesson completed',
      subtitle: 'Widgets basics',
      icon: Icons.check_circle_outline,
    ),
    ActivityItem(
      title: 'Quiz submitted',
      subtitle: 'Dart fundamentals quiz',
      icon: Icons.quiz_outlined,
    ),
    ActivityItem(
      title: 'Assignment graded',
      subtitle: 'UI layout exercise',
      icon: Icons.grade_outlined,
    ),
  ];

  // ---------- Instructor ----------
  static const instructorStats = [
    DashboardStat(
      label: 'Total courses',
      value: '8',
      icon: Icons.menu_book_outlined,
      color: Colors.indigo,
    ),
    DashboardStat(
      label: 'Published',
      value: '5',
      icon: Icons.public,
      color: Colors.green,
    ),
    DashboardStat(
      label: 'Drafts',
      value: '3',
      icon: Icons.edit_note,
      color: Colors.orange,
    ),
    DashboardStat(
      label: 'Active enrollments',
      value: '124',
      icon: Icons.groups_outlined,
      color: Colors.blue,
    ),
    DashboardStat(
      label: 'To review',
      value: '12',
      icon: Icons.assignment_late_outlined,
      color: Colors.red,
    ),
    DashboardStat(
      label: 'Avg. rating',
      value: '4.6',
      icon: Icons.star_outline,
      color: Colors.amber,
    ),
  ];

  static const instructorActions = [
    QuickAction(label: 'New course', icon: Icons.add_circle_outline),
    QuickAction(label: 'Quizzes', icon: Icons.quiz_outlined),
    QuickAction(label: 'Assignments', icon: Icons.assignment_outlined),
    QuickAction(label: 'Enrollments', icon: Icons.groups_outlined),
  ];

  static const instructorActivity = [
    ActivityItem(
      title: 'New enrollment',
      subtitle: 'Flutter for Beginners',
      icon: Icons.person_add_alt_outlined,
    ),
    ActivityItem(
      title: 'Submission received',
      subtitle: 'UI layout exercise',
      icon: Icons.upload_file_outlined,
    ),
    ActivityItem(
      title: 'Quiz attempt completed',
      subtitle: 'Dart fundamentals quiz',
      icon: Icons.quiz_outlined,
    ),
  ];

  // ---------- Admin ----------
  static const adminStats = [
    DashboardStat(
      label: 'Total users',
      value: '1,240',
      icon: Icons.people_outline,
      color: Colors.indigo,
    ),
    DashboardStat(
      label: 'Students',
      value: '1,180',
      icon: Icons.school_outlined,
      color: Colors.blue,
    ),
    DashboardStat(
      label: 'Instructors',
      value: '60',
      icon: Icons.cast_for_education,
      color: Colors.teal,
    ),
    DashboardStat(
      label: 'Published courses',
      value: '42',
      icon: Icons.menu_book_outlined,
      color: Colors.green,
    ),
    DashboardStat(
      label: 'Enrollments',
      value: '3,560',
      icon: Icons.how_to_reg_outlined,
      color: Colors.orange,
    ),
    DashboardStat(
      label: 'Completed',
      value: '910',
      icon: Icons.verified_outlined,
      color: Colors.purple,
    ),
  ];

  static const adminActions = [
    QuickAction(label: 'Users', icon: Icons.people_outline),
    QuickAction(label: 'Categories', icon: Icons.category_outlined),
    QuickAction(label: 'Courses', icon: Icons.menu_book_outlined),
    QuickAction(label: 'Enrollments', icon: Icons.how_to_reg_outlined),
    QuickAction(label: 'Reviews', icon: Icons.rate_review_outlined),
  ];

  static const adminActivity = [
    ActivityItem(
      title: 'New instructor registered',
      subtitle: 'Awaiting first course',
      icon: Icons.person_add_alt_outlined,
    ),
    ActivityItem(
      title: 'Category created',
      subtitle: 'Mobile Development',
      icon: Icons.category_outlined,
    ),
    ActivityItem(
      title: 'Review moderated',
      subtitle: 'Flutter for Beginners',
      icon: Icons.rate_review_outlined,
    ),
  ];
}

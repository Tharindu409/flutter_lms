import 'package:flutter/material.dart';
import 'package:flutter_lms/providers/assignment_provider.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/instructor_courses_provider.dart';
import 'package:flutter_lms/screens/assignment_screens.dart';
import 'package:flutter_lms/screens/courses_screen.dart';
import 'package:flutter_lms/screens/instructor_course_screens.dart';
import 'package:flutter_lms/screens/instructor_dashboard.dart';
import 'package:flutter_lms/screens/profile/profile_screen.dart';
import 'package:flutter_lms/screens/student_dashboard.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/assignment_service.dart';
import 'package:flutter_lms/services/enrollment_service.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:provider/provider.dart';

class StudentNavigationShell extends StatefulWidget {
  const StudentNavigationShell({super.key});

  @override
  State<StudentNavigationShell> createState() => _StudentNavigationShellState();
}

class _StudentNavigationShellState extends State<StudentNavigationShell> {
  int _index = 0;
  final Set<int> _visited = {0};

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().role != 'STUDENT') {
      return const _RoleDeniedScreen();
    }
    final api = context.read<ApiClient>();
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            _visited.contains(0)
                ? const StudentDashboard()
                : const SizedBox.shrink(),
            _visited.contains(1)
                ? const CoursesScreen()
                : const SizedBox.shrink(),
            _visited.contains(2)
                ? ChangeNotifierProvider(
                    create: (_) => AssignmentProvider(
                      AssignmentService(api),
                      EnrollmentService(api),
                    ),
                    child: const AssignmentsScreen(),
                  )
                : const SizedBox.shrink(),
            _visited.contains(3)
                ? const ProfileScreen()
                : const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() {
          _index = value;
          _visited.add(value);
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Assignments',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class InstructorNavigationShell extends StatefulWidget {
  const InstructorNavigationShell({super.key});

  @override
  State<InstructorNavigationShell> createState() =>
      _InstructorNavigationShellState();
}

class _InstructorNavigationShellState extends State<InstructorNavigationShell> {
  int _index = 0;
  final Set<int> _visited = {0};

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().role != 'INSTRUCTOR') {
      return const _RoleDeniedScreen();
    }
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            _visited.contains(0)
                ? const InstructorDashboard()
                : const SizedBox.shrink(),
            _visited.contains(1)
                ? const InstructorMyCoursesScreen()
                : const SizedBox.shrink(),
            _visited.contains(2)
                ? const _InstructorWorkScreen()
                : const SizedBox.shrink(),
            _visited.contains(3)
                ? const ProfileScreen()
                : const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() {
          _index = value;
          _visited.add(value);
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'My courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Submissions',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _InstructorWorkScreen extends StatefulWidget {
  const _InstructorWorkScreen();

  @override
  State<_InstructorWorkScreen> createState() => _InstructorWorkScreenState();
}

class _InstructorWorkScreenState extends State<_InstructorWorkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InstructorCoursesProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submissions and assignments')),
      body: Consumer<InstructorCoursesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.courses.isEmpty) {
            return const LoadingView(message: 'Loading your courses...');
          }
          if (provider.errorMessage != null && provider.courses.isEmpty) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: provider.refresh,
            );
          }
          if (provider.courses.isEmpty) {
            return const EmptyView(title: 'No courses available');
          }
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount:
                  provider.courses.length +
                  (provider.hasMore || provider.loadMoreError != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.courses.length) {
                  return TextButton(
                    onPressed: provider.loadMore,
                    child: Text(provider.loadMoreError ?? 'Load more courses'),
                  );
                }
                final course = provider.courses[index];
                return Card(
                  child: ListTile(
                    title: Text(course.title),
                    subtitle: Text('Manage assignments and submissions'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.instructorAssignments,
                      arguments: {
                        'courseId': course.id,
                        'courseTitle': course.title,
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RoleDeniedScreen extends StatelessWidget {
  const _RoleDeniedScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('You do not have access to this page')),
  );
}

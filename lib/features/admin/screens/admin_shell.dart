import 'package:flutter/material.dart';
import 'package:flutter_lms/features/admin/categories/admin_categories_provider.dart';
import 'package:flutter_lms/features/admin/categories/admin_categories_service.dart';
import 'package:flutter_lms/features/admin/courses/admin_courses_provider.dart';
import 'package:flutter_lms/features/admin/courses/admin_courses_service.dart';
import 'package:flutter_lms/features/admin/dashboard/admin_dashboard_provider.dart';
import 'package:flutter_lms/features/admin/dashboard/admin_dashboard_service.dart';
import 'package:flutter_lms/features/admin/enrollments/admin_enrollments_provider.dart';
import 'package:flutter_lms/features/admin/enrollments/admin_enrollments_service.dart';
import 'package:flutter_lms/features/admin/reviews/admin_reviews_provider.dart';
import 'package:flutter_lms/features/admin/reviews/admin_reviews_service.dart';
import 'package:flutter_lms/features/admin/screens/admin_screens.dart';
import 'package:flutter_lms/features/admin/users/admin_users_provider.dart';
import 'package:flutter_lms/features/admin/users/admin_users_service.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:provider/provider.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    this.initialIndex = 0,
    this.moreInitialSection = 'enrollments',
  });

  final int initialIndex;
  final String moreInitialSection;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late int _index = widget.initialIndex;
  late final Set<int> _visited = {widget.initialIndex};
  int _returnIndex = 0;
  late String _activeMoreSection = widget.moreInitialSection;
  String? _pendingCourseId;

  void _openEnrollments(String courseId) {
    setState(() {
      if (_index != 4) _returnIndex = _index;
      _activeMoreSection = 'enrollments';
      _pendingCourseId = courseId;
      _index = 4;
      _visited.add(4);
    });
  }

  void _openMore(String section) {
    setState(() {
      if (_index != 4) _returnIndex = _index;
      _activeMoreSection = section;
      _pendingCourseId = null;
      _index = 4;
      _visited.add(4);
    });
  }

  void _closeMore() {
    if (!mounted || _index != 4) return;
    setState(() => _index = _returnIndex);
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AdminDashboardProvider(AdminDashboardService(api)),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminUsersProvider(AdminUsersService(api)),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminCategoriesProvider(AdminCategoriesService(api)),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminCoursesProvider(AdminCoursesService(api)),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminEnrollmentsProvider(AdminEnrollmentsService(api)),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminReviewsProvider(AdminReviewsService(api)),
        ),
      ],
      child: Builder(
        builder: (context) {
          if (context.watch<AuthProvider>().role != 'ADMIN') {
            return const Scaffold(
              body: Center(child: Text('You do not have access to this page')),
            );
          }
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFF2563EB),
                secondary: const Color(0xFF2563EB),
                tertiary: const Color(0xFF1D4ED8),
                surface: Colors.white,
                onSurface: const Color(0xFF111827),
                onSurfaceVariant: const Color(0xFF5B6472),
                primaryContainer: const Color(0xFFDBEAFE),
                onPrimaryContainer: const Color(0xFF1E3A8A),
                outline: const Color(0xFFD1D5DB),
                outlineVariant: const Color(0xFFE5E7EB),
              ),
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: Theme.of(context).appBarTheme.copyWith(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF111827),
                surfaceTintColor: Colors.transparent,
              ),
              textTheme: Theme.of(context).textTheme.copyWith(
                headlineSmall: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: const Color(0xFF111827)),
                titleLarge: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: const Color(0xFF111827)),
                titleMedium: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: const Color(0xFF111827)),
                bodyLarge: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: const Color(0xFF111827)),
                bodyMedium: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: const Color(0xFF5B6472)),
                bodySmall: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFF6B7280)),
              ),
              inputDecorationTheme: Theme.of(context).inputDecorationTheme
                  .copyWith(
                    fillColor: const Color(0xFFF9FAFB),
                    prefixIconColor: const Color(0xFF6B7280),
                    suffixIconColor: const Color(0xFF6B7280),
                    labelStyle: const TextStyle(color: Color(0xFF5B6472)),
                    floatingLabelStyle: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xFFDBEAFE),
                elevation: 0,
                height: 74,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF5B6472),
                  );
                }),
              ),
            ),
            child: PopScope(
              canPop: _index != 4,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && _index == 4) _closeMore();
              },
              child: Scaffold(
                body: SafeArea(
                  child: IndexedStack(
                    index: _index,
                    children: [
                      _visited.contains(0)
                          ? AdminDashboardScreen(
                              onOpenMore: () => _openMore('enrollments'),
                            )
                          : const SizedBox.shrink(),
                      _visited.contains(1)
                          ? AdminUsersScreen(
                              onOpenMore: () => _openMore('enrollments'),
                            )
                          : const SizedBox.shrink(),
                      _visited.contains(2)
                          ? AdminCoursesScreen(
                              onEnrollments: _openEnrollments,
                              onOpenMore: () => _openMore('enrollments'),
                            )
                          : const SizedBox.shrink(),
                      _visited.contains(3)
                          ? AdminCategoriesScreen(
                              onOpenMore: () => _openMore('enrollments'),
                            )
                          : const SizedBox.shrink(),
                      _visited.contains(4)
                          ? AdminMoreScreen(
                              initialCourseId: _pendingCourseId,
                              initialSection: _activeMoreSection,
                              onCourseHandled: () {
                                if (!mounted || _pendingCourseId == null) {
                                  return;
                                }
                                setState(() => _pendingCourseId = null);
                              },
                              onBack: _closeMore,
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
                bottomNavigationBar: _index == 4
                    ? null
                    : NavigationBar(
                        selectedIndex: _index,
                        onDestinationSelected: (index) => setState(() {
                          _index = index;
                          _visited.add(index);
                        }),
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            selectedIcon: Icon(Icons.dashboard),
                            label: 'Dashboard',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.people_outline),
                            selectedIcon: Icon(Icons.people),
                            label: 'Users',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.menu_book_outlined),
                            selectedIcon: Icon(Icons.menu_book),
                            label: 'Courses',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.category_outlined),
                            selectedIcon: Icon(Icons.category),
                            label: 'Categories',
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/profile_provider.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/auth_service.dart';
import 'package:flutter_lms/services/profile_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_lms/utils/app_navigator.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/providers/course_catalog_provider.dart';
import 'package:flutter_lms/providers/my_courses_provider.dart';
import 'package:flutter_lms/providers/notification_provider.dart';
import 'package:flutter_lms/services/course_service.dart';
import 'package:flutter_lms/services/enrollment_service.dart';
import 'package:flutter_lms/services/notification_service.dart';
import 'package:flutter_lms/providers/instructor_courses_provider.dart';
import 'package:flutter_lms/providers/instructor_dashboard_provider.dart';
import 'package:flutter_lms/services/instructor_course_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final tokenStorage = TokenStorage();
  late final AuthProvider authProvider;
  late final ProfileProvider profileProvider;
  final apiClient = ApiClient(
    tokenStorage,
    onSessionExpired: () {
      final wasLoggedIn = authProvider.isLoggedIn;
      authProvider.handleSessionExpired();
      profileProvider.reset();
      if (wasLoggedIn) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    },
  );
  final authService = AuthService(apiClient, tokenStorage);
  final profileService = ProfileService(apiClient);
  authProvider = AuthProvider(authService);
  profileProvider = ProfileProvider(profileService);

  final courseService = CourseService(apiClient);
  final enrollmentService = EnrollmentService(apiClient);
  final notificationService = NotificationService(apiClient);
  final catalogProvider = CourseCatalogProvider(courseService);
  final myCoursesProvider = MyCoursesProvider(enrollmentService);
  final notificationProvider = NotificationProvider(notificationService);
  var wasLoggedIn = false;

  // Clear cached course data when the user logs out or the session expires,
  // so the next user never sees the previous user's courses.

  final instructorCourseService = InstructorCourseService(apiClient);
  final instructorDashboardProvider = InstructorDashboardProvider(
    instructorCourseService,
  );
  final instructorCoursesProvider = InstructorCoursesProvider(
    instructorCourseService,
  );

  authProvider.addListener(() {
    final isLoggedIn = authProvider.isLoggedIn;
    if (!isLoggedIn) {
      catalogProvider.reset();
      myCoursesProvider.reset();
      notificationProvider.reset();
      instructorDashboardProvider.reset();
      instructorCoursesProvider.reset();
    } else if (!wasLoggedIn) {
      notificationProvider.refreshUnreadCount();
    }
    wasLoggedIn = isLoggedIn;
  });

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),
        Provider<ProfileService>.value(value: profileService),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
        ChangeNotifierProvider<CourseCatalogProvider>.value(
          value: catalogProvider,
        ),
        ChangeNotifierProvider<MyCoursesProvider>.value(
          value: myCoursesProvider,
        ),
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
        Provider<InstructorCourseService>.value(value: instructorCourseService),
        ChangeNotifierProvider<InstructorDashboardProvider>.value(
          value: instructorDashboardProvider,
        ),
        ChangeNotifierProvider<InstructorCoursesProvider>.value(
          value: instructorCoursesProvider,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter LMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

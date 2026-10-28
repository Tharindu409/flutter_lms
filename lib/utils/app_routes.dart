import 'package:flutter/material.dart';
import 'package:flutter_lms/screens/admin_dashboard.dart';
import 'package:flutter_lms/screens/auth/forgot_password_screen.dart';
import 'package:flutter_lms/screens/auth/login_screen.dart';
import 'package:flutter_lms/screens/auth/register_instructor_screen.dart';
import 'package:flutter_lms/screens/auth/register_student_screen.dart';
import 'package:flutter_lms/screens/auth/reset_password_screen.dart';
import 'package:flutter_lms/screens/auth/verify_otp_screen.dart';
import 'package:flutter_lms/screens/instructor_dashboard.dart';
import 'package:flutter_lms/screens/onboarding_screen.dart';
import 'package:flutter_lms/screens/profile/edit_profile_screen.dart';
import 'package:flutter_lms/screens/profile/profile_screen.dart';
import 'package:flutter_lms/screens/splash_screen.dart';
import 'package:flutter_lms/screens/student_dashboard.dart';
import 'package:flutter_lms/screens/notifications_screen.dart';
import 'package:flutter_lms/screens/courses_screen.dart';
import 'package:flutter_lms/screens/student_learning_screens.dart';
import 'package:flutter_lms/providers/course_detail_provider.dart';
import 'package:flutter_lms/providers/learning_provider.dart';
import 'package:flutter_lms/providers/quiz_provider.dart';
import 'package:flutter_lms/providers/assignment_provider.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/course_service.dart';
import 'package:flutter_lms/services/enrollment_service.dart';
import 'package:flutter_lms/services/learning_service.dart';
import 'package:flutter_lms/services/quiz_service.dart';
import 'package:flutter_lms/services/assignment_service.dart';
import 'package:flutter_lms/services/instructor_lesson_service.dart';
import 'package:flutter_lms/screens/assignment_screens.dart';
import 'package:flutter_lms/screens/instructor_lesson_screens.dart';
import 'package:flutter_lms/screens/instructor_quiz_screens.dart';
import 'package:flutter_lms/providers/instructor_quiz_provider.dart';
import 'package:flutter_lms/services/instructor_quiz_service.dart';
import 'package:flutter_lms/screens/instructor_assignment_screens.dart';
import 'package:flutter_lms/providers/instructor_assignment_provider.dart';
import 'package:flutter_lms/services/instructor_assignment_service.dart';
import 'package:provider/provider.dart';

class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const studentDashboard = '/student';
  static const instructorDashboard = '/instructor';
  static const adminDashboard = '/admin';
  static const registerStudent = '/register/student';
  static const registerInstructor = '/register/instructor';
  static const verifyOtp = '/verify-otp';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const courses = '/courses';
  static const courseDetail = '/courses/detail';
  static const myCourses = '/my-courses';
  static const curriculum = '/learning/curriculum';
  static const lesson = '/learning/lesson';
  static const notifications = '/notifications';
  static const assignments = '/assignments';
  static const assignmentDetail = '/assignments/detail';
  static const instructorLessonCourses = '/instructor/lessons';
  static const instructorQuizzes = '/instructor/course-quizzes';
  static const instructorAssignments = '/instructor/course-assignments';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    login: (_) => const LoginScreen(),
    studentDashboard: (_) => const StudentDashboard(),
    instructorDashboard: (_) => const InstructorDashboard(),
    adminDashboard: (_) => const AdminDashboard(),
    registerStudent: (_) => const RegisterStudentScreen(),
    registerInstructor: (_) => const RegisterInstructorScreen(),
    verifyOtp: (_) => const VerifyOtpScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    resetPassword: (_) => const ResetPasswordScreen(),
    profile: (_) => const ProfileScreen(),
    editProfile: (_) => const EditProfileScreen(),
    courses: (_) => const CoursesScreen(),
    notifications: (_) => const NotificationsScreen(),
    instructorLessonCourses: (_) => const InstructorLessonCoursesScreen(),
    assignments: (context) => ChangeNotifierProvider<AssignmentProvider>(
      create: (_) {
        final apiClient = context.read<ApiClient>();
        return AssignmentProvider(
          AssignmentService(apiClient),
          EnrollmentService(apiClient),
        );
      },
      child: const AssignmentsScreen(),
    ),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final arguments = settings.arguments;
    switch (settings.name) {
      case courseDetail:
        final courseId = _stringArgument(arguments, 'courseId');
        if (courseId == null) return _invalidRoute();
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) {
            final apiClient = context.read<ApiClient>();
            return ChangeNotifierProvider<CourseDetailProvider>(
              create: (_) => CourseDetailProvider(
                CourseService(apiClient),
                EnrollmentService(apiClient),
              ),
              child: CourseDetailScreen(courseId: courseId),
            );
          },
        );
      case myCourses:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const MyCoursesScreen(),
        );
      case curriculum:
        final courseId = _stringArgument(arguments, 'courseId');
        if (courseId == null) return _invalidRoute();
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) {
            final apiClient = context.read<ApiClient>();
            return MultiProvider(
              providers: [
                ChangeNotifierProvider<LearningProvider>(
                  create: (_) => LearningProvider(
                    CourseService(apiClient),
                    LearningService(apiClient),
                    EnrollmentService(apiClient),
                  ),
                ),
                ChangeNotifierProvider<QuizProvider>(
                  create: (_) => QuizProvider(QuizService(apiClient)),
                ),
                ChangeNotifierProvider<AssignmentProvider>(
                  create: (_) => AssignmentProvider(
                    AssignmentService(apiClient),
                    EnrollmentService(apiClient),
                  ),
                ),
              ],
              child: CurriculumScreen(
                courseId: courseId,
                title:
                    _stringArgument(arguments, 'title') ?? 'Course curriculum',
                enrollmentId: _stringArgument(arguments, 'enrollmentId'),
              ),
            );
          },
        );
      case lesson:
        final lessonId = _stringArgument(arguments, 'lessonId');
        final learningProvider = arguments is Map
            ? arguments['learningProvider']
            : null;
        if (lessonId == null || learningProvider is! LearningProvider) {
          return _invalidRoute();
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ChangeNotifierProvider<LearningProvider>.value(
            value: learningProvider,
            child: LessonPlayerScreen(
              lessonId: lessonId,
              title: _stringArgument(arguments, 'title') ?? 'Lesson',
            ),
          ),
        );
      case assignmentDetail:
        final assignmentId = _stringArgument(arguments, 'assignmentId');
        if (assignmentId == null) return _invalidRoute();
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) {
            final apiClient = context.read<ApiClient>();
            return ChangeNotifierProvider<AssignmentProvider>(
              create: (_) => AssignmentProvider(
                AssignmentService(apiClient),
                EnrollmentService(apiClient),
              ),
              child: AssignmentDetailScreen(assignmentId: assignmentId),
            );
          },
        );
      case instructorQuizzes:
        final courseId = _stringArgument(arguments, 'courseId');
        if (courseId == null) return _invalidRoute();
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) {
            final apiClient = context.read<ApiClient>();
            return ChangeNotifierProvider<InstructorQuizProvider>(
              create: (_) => InstructorQuizProvider(
                InstructorQuizService(apiClient),
                InstructorLessonService(apiClient),
              ),
              child: InstructorCourseQuizzesScreen(
                courseId: courseId,
                courseTitle:
                    _stringArgument(arguments, 'courseTitle') ?? 'Course',
              ),
            );
          },
        );
      case instructorAssignments:
        final courseId = _stringArgument(arguments, 'courseId');
        if (courseId == null) return _invalidRoute();
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) {
            final apiClient = context.read<ApiClient>();
            return ChangeNotifierProvider<InstructorAssignmentProvider>(
              create: (_) => InstructorAssignmentProvider(
                InstructorAssignmentService(apiClient),
                InstructorLessonService(apiClient),
              ),
              child: InstructorCourseAssignmentsScreen(
                courseId: courseId,
                courseTitle:
                    _stringArgument(arguments, 'courseTitle') ?? 'Course',
              ),
            );
          },
        );
      default:
        return null;
    }
  }

  static String? _stringArgument(dynamic arguments, String key) {
    if (arguments is String && key == 'courseId') return arguments;
    if (arguments is Map) {
      final value = arguments[key]?.toString();
      return value == null || value.isEmpty ? null : value;
    }
    return null;
  }

  static Route<dynamic> _invalidRoute() {
    return MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Unable to open page')),
        body: const Center(
          child: Text('The requested course or lesson is unavailable.'),
        ),
      ),
    );
  }

  /// Dashboard route for the role returned by the backend.
  static String? homeForRole(String? role) {
    switch (role) {
      case 'STUDENT':
        return studentDashboard;
      case 'INSTRUCTOR':
        return instructorDashboard;
      case 'ADMIN':
        return adminDashboard;
      default:
        return null;
    }
  }
}

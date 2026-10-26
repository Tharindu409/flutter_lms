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

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),
        Provider<ProfileService>.value(value: profileService),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
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
    );
  }
}

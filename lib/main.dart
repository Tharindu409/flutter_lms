import 'package:flutter/material.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/services/auth_service.dart';
import 'package:flutter_lms/utils/app_navigator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage);
  final authService = AuthService(apiClient, tokenStorage);

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService),
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
      title: 'Flutter LMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}

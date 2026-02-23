import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/history_screen/history_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/privacy_policy_screen/privacy_policy_screen.dart';
import '../presentation/terms_of_service_screen/terms_of_service_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String settings = '/settings-screen';
  static const String history = '/history-screen';
  static const String home = '/home-screen';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    settings: (context) => const SettingsScreen(),
    history: (context) => const HistoryScreen(),
    home: (context) => const HomeScreen(),
    privacyPolicy: (context) => const PrivacyPolicyScreen(),
    termsOfService: (context) => const TermsOfServiceScreen(),
  };
}

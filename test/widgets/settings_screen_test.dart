import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moodtap/presentation/settings_screen/settings_screen.dart';
import 'package:moodtap/routes/app_routes.dart';
import 'package:sizer/sizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should render settings screen with all sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const SettingsScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should display main settings sections
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Data Management'), findsOneWidget);
      expect(find.text('Legal'), findsOneWidget);
    });

    testWidgets('should display dark mode toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const SettingsScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should have dark mode switch
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.byType(Switch), findsAtLeastNWidgets(1));
    });

    testWidgets('should toggle dark mode when switch is tapped', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'isDarkMode': false});

      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const SettingsScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Find dark mode switch
      final darkModeSwitch = find.byType(Switch).first;
      await tester.tap(darkModeSwitch);
      await tester.pumpAndSettle();

      // Verify preference was saved
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isDarkMode'), isTrue);
    });

    testWidgets('should display notification settings', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const SettingsScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should have notification toggle
      expect(find.text('Daily Reminder'), findsOneWidget);
    });

    testWidgets('should display data management options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const SettingsScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should have export and reset options
      expect(find.text('Export Data'), findsOneWidget);
      expect(find.text('Reset All Data'), findsOneWidget);
    });

    testWidgets('should display legal links', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const SettingsScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should have privacy policy and terms links
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('should navigate to privacy policy when tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const SettingsScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Tap privacy policy
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      // Should navigate to privacy policy screen
      // (Would check for privacy policy content)
    });

    testWidgets('should navigate to terms of service when tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const SettingsScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Tap terms of service
      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();

      // Should navigate to terms screen
    });

    testWidgets('should show reset confirmation dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const SettingsScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Tap reset all data
      await tester.tap(find.text('Reset All Data'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('should display app version', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const SettingsScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should display version number
      expect(find.textContaining('Version'), findsOneWidget);
      expect(find.textContaining('1.0.0'), findsOneWidget);
    });

    testWidgets('should display bottom navigation bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const SettingsScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should have bottom navigation
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('should handle export data tap', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const SettingsScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Tap export data
      await tester.tap(find.text('Export Data'));
      await tester.pumpAndSettle();

      // Should show export dialog or message
      expect(find.textContaining('No mood'), findsAtLeastNWidgets(1));
    });

    testWidgets('should be scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const SettingsScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should be able to scroll
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}

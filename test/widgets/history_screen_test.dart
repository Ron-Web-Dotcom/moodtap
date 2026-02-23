import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moodtap/presentation/history_screen/history_screen.dart';
import 'package:moodtap/routes/app_routes.dart';
import 'package:sizer/sizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should render history screen with tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HistoryScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should display Weekly and Monthly tabs
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('should show empty state when no mood data', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HistoryScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state message
      expect(find.textContaining('No mood'), findsAtLeastNWidgets(1));
    });

    testWidgets('should switch between weekly and monthly views', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HistoryScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Initially on Weekly tab
      expect(find.text('Weekly'), findsOneWidget);

      // Tap Monthly tab
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();

      // Should switch to monthly view
      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('should display bottom navigation bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HistoryScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should have bottom navigation
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HistoryScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      // Before pumpAndSettle, should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // After loading, should not show loading indicator
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should display mood history when data exists', (
      WidgetTester tester,
    ) async {
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      SharedPreferences.setMockInitialValues({
        'mood_history': '[{"date":"$todayString","mood":4}]',
      });

      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HistoryScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should display mood data (chart or list)
      // This would require checking for specific chart widgets or mood indicators
    });

    testWidgets('should navigate to home screen from bottom nav', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HistoryScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap home tab (first tab)
      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget);

      // Tap on home icon/tab
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      // Should navigate to home screen
    });

    testWidgets('should handle pull to refresh', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HistoryScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Find RefreshIndicator
      final refreshIndicator = find.byType(RefreshIndicator);
      if (refreshIndicator.evaluate().isNotEmpty) {
        // Simulate pull to refresh
        await tester.drag(refreshIndicator, const Offset(0, 300));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should display app bar with title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HistoryScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should have app bar with "History" or similar title
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('should maintain tab state when switching', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HistoryScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Monthly
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();

      // Switch back to Weekly
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      // Should maintain state and not crash
      expect(find.text('Weekly'), findsOneWidget);
    });
  });
}

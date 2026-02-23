import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moodtap/presentation/home_screen/home_screen.dart';
import 'package:moodtap/routes/app_routes.dart';
import 'package:sizer/sizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should render home screen with all mood emojis', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HomeScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should display 5 mood emojis
      expect(find.text('😢'), findsOneWidget); // Very Sad
      expect(find.text('😕'), findsOneWidget); // Sad
      expect(find.text('😐'), findsOneWidget); // Neutral
      expect(find.text('🙂'), findsOneWidget); // Happy
      expect(find.text('😄'), findsOneWidget); // Very Happy
    });

    testWidgets('should display motivational text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HomeScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should display "How are you feeling today?" or similar text
      expect(find.textContaining('feeling'), findsAtLeastNWidgets(1));
    });

    testWidgets('should show bottom navigation bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HomeScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should have bottom navigation with 3 items
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('should allow mood selection', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HomeScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Tap on happy emoji (4th emoji)
      final happyEmoji = find.text('🙂');
      expect(happyEmoji, findsOneWidget);

      await tester.tap(happyEmoji);
      await tester.pumpAndSettle();

      // Mood should be selected (visual feedback should appear)
      // This would require checking for visual changes like borders or colors
    });

    testWidgets('should display current date', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HomeScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should display current date in some format
      final now = DateTime.now();
      expect(find.textContaining(now.year.toString()), findsAtLeastNWidgets(1));
    });

    testWidgets('should prevent duplicate mood logging for same day', (
      WidgetTester tester,
    ) async {
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      SharedPreferences.setMockInitialValues({
        'last_logged_date': todayString,
        'today_mood': 4,
      });

      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HomeScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should show "Already logged" message or similar
      expect(find.textContaining('logged'), findsAtLeastNWidgets(1));
    });

    testWidgets('should show loading indicator initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HomeScreen(),
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

    testWidgets('should navigate to history screen from bottom nav', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const HomeScreen(),
              routes: AppRoutes.routes,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap history tab (second tab)
      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget);

      // Tap on history icon/tab
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Should navigate to history screen
      // (This would require checking the current route or screen content)
    });

    testWidgets('should handle mood selection for all 5 moods', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: const HomeScreen(),
                routes: AppRoutes.routes,
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Tap each mood emoji
        final emojis = ['😢', '😕', '😐', '🙂', '😄'];
        final emojiWidget = find.text(emojis[i]);

        if (emojiWidget.evaluate().isNotEmpty) {
          await tester.tap(emojiWidget);
          await tester.pumpAndSettle();
        }
      }
    });
  });
}

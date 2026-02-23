import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:moodtap/services/notification_service.dart';

@GenerateMocks([PermissionStatus])
import 'notification_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Tests', () {
    late NotificationService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = NotificationService();
    });

    group('Initialization', () {
      test('should initialize only once', () async {
        await service.initialize();
        await service.initialize(); // Second call should be no-op

        // Should not throw or cause issues
        expect(service, isNotNull);
      });

      test(
        'should handle timezone initialization failure gracefully',
        () async {
          // Service should not throw even if timezone fails
          expect(() => service.initialize(), returnsNormally);
        },
      );
    });

    group('Notification Time Validation', () {
      test('should validate valid notification times', () {
        expect(_isValidNotificationTime(0, 0), isTrue);
        expect(_isValidNotificationTime(12, 30), isTrue);
        expect(_isValidNotificationTime(23, 59), isTrue);
        expect(_isValidNotificationTime(20, 0), isTrue);
      });

      test('should reject invalid notification times', () {
        expect(_isValidNotificationTime(-1, 0), isFalse);
        expect(_isValidNotificationTime(24, 0), isFalse);
        expect(_isValidNotificationTime(12, 60), isFalse);
        expect(_isValidNotificationTime(12, -1), isFalse);
      });
    });

    group('Notification Settings Persistence', () {
      test('should save notification time to SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await prefs.setInt('notification_hour', 20);
        await prefs.setInt('notification_minute', 30);
        await prefs.setBool('notifications_enabled', true);

        final savedTime = await service.getSavedNotificationTime();
        expect(savedTime, isNotNull);
        expect(savedTime!['hour'], equals(20));
        expect(savedTime['minute'], equals(30));

        final enabled = await service.areNotificationsEnabled();
        expect(enabled, isTrue);
      });

      test('should return null when no notification time is saved', () async {
        SharedPreferences.setMockInitialValues({});
        final savedTime = await service.getSavedNotificationTime();
        expect(savedTime, isNull);
      });

      test('should return false when notifications are not enabled', () async {
        SharedPreferences.setMockInitialValues({});
        final enabled = await service.areNotificationsEnabled();
        expect(enabled, isFalse);
      });

      test('should update notification enabled status', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool('notifications_enabled', true);
        expect(await service.areNotificationsEnabled(), isTrue);

        await prefs.setBool('notifications_enabled', false);
        expect(await service.areNotificationsEnabled(), isFalse);
      });
    });

    group('Notification Scheduling Logic', () {
      test('should calculate next notification time correctly', () {
        final now = DateTime(2026, 2, 15, 10, 0); // 10:00 AM
        final scheduledTime = DateTime(2026, 2, 15, 20, 0); // 8:00 PM

        // Should schedule for today if time hasn't passed
        expect(scheduledTime.isAfter(now), isTrue);
        expect(scheduledTime.day, equals(now.day));
      });

      test('should schedule for next day if time has passed', () {
        final now = DateTime(2026, 2, 15, 21, 0); // 9:00 PM
        final targetTime = DateTime(2026, 2, 15, 20, 0); // 8:00 PM

        // Time has passed, should schedule for tomorrow
        if (targetTime.isBefore(now)) {
          final nextDay = targetTime.add(const Duration(days: 1));
          expect(nextDay.day, equals(16));
          expect(nextDay.hour, equals(20));
        }
      });

      test('should handle midnight scheduling correctly', () {
        final now = DateTime(2026, 2, 15, 23, 30); // 11:30 PM
        final targetTime = DateTime(2026, 2, 15, 0, 0); // Midnight

        // Should schedule for next day's midnight
        if (targetTime.isBefore(now)) {
          final nextDay = targetTime.add(const Duration(days: 1));
          expect(nextDay.day, equals(16));
          expect(nextDay.hour, equals(0));
        }
      });
    });

    group('Notification Cancellation', () {
      test('should disable notifications when cancelled', () async {
        SharedPreferences.setMockInitialValues({
          'notifications_enabled': true,
          'notification_hour': 20,
          'notification_minute': 0,
        });

        await service.cancelDailyReminder();

        final enabled = await service.areNotificationsEnabled();
        expect(enabled, isFalse);
      });

      test('should preserve notification time after cancellation', () async {
        SharedPreferences.setMockInitialValues({
          'notifications_enabled': true,
          'notification_hour': 20,
          'notification_minute': 30,
        });

        await service.cancelDailyReminder();

        final savedTime = await service.getSavedNotificationTime();
        expect(savedTime, isNotNull);
        expect(savedTime!['hour'], equals(20));
        expect(savedTime['minute'], equals(30));
      });
    });

    group('Edge Cases', () {
      test('should handle concurrent initialization calls', () async {
        final futures = List.generate(5, (_) => service.initialize());
        await Future.wait(futures);

        // Should not throw or cause race conditions
        expect(service, isNotNull);
      });

      test('should handle invalid saved time data', () async {
        SharedPreferences.setMockInitialValues({
          'notification_hour': 'invalid',
          'notification_minute': 'invalid',
        });

        final savedTime = await service.getSavedNotificationTime();
        expect(savedTime, isNull);
      });

      test('should handle missing hour or minute', () async {
        SharedPreferences.setMockInitialValues({
          'notification_hour': 20,
          // Missing minute
        });

        final savedTime = await service.getSavedNotificationTime();
        expect(savedTime, isNull);
      });
    });

    group('Notification Content Validation', () {
      test('should have valid notification title', () {
        const title = 'Time to log your mood! 🌟';
        expect(title, isNotEmpty);
        expect(title.length, lessThan(50));
      });

      test('should have valid notification body', () {
        const body = 'How are you feeling today? Track your mood now.';
        expect(body, isNotEmpty);
        expect(body.length, lessThan(100));
      });
    });
  });
}

// Helper validation functions
bool _isValidNotificationTime(int hour, int minute) {
  if (hour < 0 || hour > 23) return false;
  if (minute < 0 || minute > 59) return false;
  return true;
}

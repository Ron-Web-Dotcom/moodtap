import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:sentry_flutter/sentry_flutter.dart';

/// Service for managing daily mood reminder notifications
/// Optimized for battery efficiency with exact alarm scheduling
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service with platform-specific settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone database with error handling
      try {
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation(tz.local.name));
      } catch (e) {
        // Fallback to UTC if timezone initialization fails
        try {
          tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (e) {
          await Sentry.captureException(
            e,
            hint: Hint.withMap({'context': 'Timezone initialization'}),
          );
          // Silent fail - notifications will be disabled
          return;
        }
      }

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(initSettings);
      _isInitialized = true;
    } catch (e) {
      await Sentry.captureException(
        e,
        hint: Hint.withMap({'context': 'NotificationService initialization'}),
      );
    }
  }

  /// Request notification permissions (required for Android 13+ and iOS)
  /// Returns true if granted, false if denied
  /// Shows guidance dialog if permanently denied
  Future<bool> requestPermissions() async {
    try {
      final status = await Permission.notification.request();

      if (status.isPermanentlyDenied) {
        // Permission permanently denied - user must enable in settings
        // Return false to let caller show guidance dialog
        return false;
      }

      return status.isGranted;
    } catch (e) {
      await Sentry.captureException(
        e,
        hint: Hint.withMap({'context': 'requestPermissions'}),
      );
      return false;
    }
  }

  /// Check if notification permissions are granted
  Future<bool> hasPermissions() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Check if permissions are permanently denied
  Future<bool> isPermissionPermanentlyDenied() async {
    final status = await Permission.notification.status;
    return status.isPermanentlyDenied;
  }

  /// Schedule daily notification at specified time
  /// Uses exactAllowWhileIdle for battery-efficient scheduling
  Future<void> scheduleDailyReminder(int hour, int minute) async {
    try {
      if (!_isInitialized) await initialize();

      // Cancel any existing notifications
      await _notifications.cancel(0);

      // Create notification time
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'mood_reminder',
        'Daily Mood Reminder',
        channelDescription: 'Daily reminder to log your mood',
        importance: Importance.high,
        priority: Priority.high,
        // Battery optimization: Use exact alarm only when necessary
        enableVibration: false,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        0,
        'Time to log your mood! 🌟',
        'How are you feeling today? Track your mood now.',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Save notification time to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', hour);
      await prefs.setInt('notification_minute', minute);
      await prefs.setBool('notifications_enabled', true);
    } catch (e) {
      await Sentry.captureException(
        e,
        hint: Hint.withMap({
          'context': 'scheduleDailyReminder',
          'hour': hour,
          'minute': minute,
        }),
      );
      rethrow;
    }
  }

  /// Cancel daily reminder
  Future<void> cancelDailyReminder() async {
    try {
      await _notifications.cancel(0);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', false);
    } catch (e) {
      await Sentry.captureException(
        e,
        hint: Hint.withMap({'context': 'cancelDailyReminder'}),
      );
    }
  }

  /// Get saved notification time from preferences
  Future<Map<String, int>?> getSavedNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notification_hour');
    final minute = prefs.getInt('notification_minute');

    if (hour != null && minute != null) {
      return {'hour': hour, 'minute': minute};
    }
    return null;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }
}

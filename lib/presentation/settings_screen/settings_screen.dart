
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/reset_data_dialog_widget.dart';
import './widgets/settings_section_widget.dart';

/// Settings screen for MoodTap application
/// Provides dark mode toggle and data reset functionality
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _currentIndex = 2; // Settings tab index
  bool _isDarkMode = false;
  bool _isLoading = true;
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _loadNotificationSettings();
  }

  /// Load saved theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _isDarkMode = prefs.getBool('isDarkMode') ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Load notification settings
  Future<void> _loadNotificationSettings() async {
    try {
      final notificationService = NotificationService();
      final enabled = await notificationService.areNotificationsEnabled();
      final savedTime = await notificationService.getSavedNotificationTime();

      if (mounted) {
        setState(() {
          _notificationsEnabled = enabled;
          if (savedTime != null) {
            _notificationTime = TimeOfDay(
              hour: savedTime['hour']!,
              minute: savedTime['minute']!,
            );
          }
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Show permission denied dialog with guidance
  Future<void> _showPermissionDeniedDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Permission Required'),
        content: const Text(
          'MoodTap needs notification permission to send you daily reminders. '
          'Please enable notifications in your device settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Toggle notifications on/off
  Future<void> _toggleNotifications(bool value) async {
    try {
      final notificationService = NotificationService();

      if (value) {
        // Check if permission is permanently denied first
        final isPermanentlyDenied = await notificationService
            .isPermissionPermanentlyDenied();

        if (isPermanentlyDenied) {
          // Show guidance dialog
          await _showPermissionDeniedDialog();
          return;
        }

        // Request permissions
        final hasPermission = await notificationService.requestPermissions();
        if (!hasPermission) {
          // Permission denied - show guidance
          await _showPermissionDeniedDialog();
          return;
        }

        // Schedule notification
        await notificationService.scheduleDailyReminder(
          _notificationTime.hour,
          _notificationTime.minute,
        );
      } else {
        // Cancel notification
        await notificationService.cancelDailyReminder();
      }

      if (mounted) {
        setState(() {
          _notificationsEnabled = value;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Show time picker for notification time
  Future<void> _selectNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );

    if (picked != null && picked != _notificationTime) {
      if (mounted) {
        setState(() {
          _notificationTime = picked;
        });
      }

      // If notifications are enabled, reschedule with new time
      if (_notificationsEnabled) {
        try {
          await NotificationService().scheduleDailyReminder(
            picked.hour,
            picked.minute,
          );
        } catch (e) {
          // Silent fail
        }
      }
    }
  }

  /// Toggle dark mode and save preference
  Future<void> _toggleDarkMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', value);

      if (mounted) {
        setState(() {
          _isDarkMode = value;
        });

        // Update theme immediately by accessing root MyApp state
        final myAppState = context
            .findRootAncestorStateOfType<State<StatefulWidget>>();
        if (myAppState != null) {
          // Access the updateThemeMode method from _MyAppState
          final dynamic appState = myAppState;
          if (appState.runtimeType.toString() == '_MyAppState') {
            try {
              (appState as dynamic).updateThemeMode(value);
            } catch (e) {
              // Silent fail - theme will update on next app restart
            }
          }
        }
      }
    } catch (e) {
      // Silent fail - theme preference saved but visual update failed
    }
  }

  /// Show confirmation dialog before resetting data
  Future<void> _showResetDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ResetDataDialogWidget(),
    );

    if (result == true && mounted) {
      await _resetAllData();
    }
  }

  /// Reset all mood data and navigate to splash screen
  Future<void> _resetAllData() async {
    try {
      // Clear Supabase data first
      try {
        await SupabaseService.instance.deleteAllMoods();
      } catch (e) {
        debugPrint('Failed to clear Supabase data: $e');
      }

      // Clear local SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      // Clear all mood-related data but keep theme preference
      final isDarkMode = prefs.getBool('isDarkMode') ?? false;
      await prefs.clear();
      await prefs.setBool('isDarkMode', isDarkMode);

      if (mounted) {
        // Navigate to splash screen to restart app flow
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.splash,
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Failed to reset data: $e');
    }
  }

  /// Export mood data as CSV
  Future<void> _exportData() async {
    try {
      final moods = await SupabaseService.instance.getAllMoods();

      if (moods.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No mood data to export'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Create CSV content
      final csvContent = StringBuffer();
      csvContent.writeln('Date,Mood,Mood Label');

      for (final mood in moods) {
        final date = mood['date'] as String;
        final moodValue = mood['mood'] as int;
        final moodLabel = _getMoodLabel(moodValue);
        csvContent.writeln('$date,$moodValue,$moodLabel');
      }

      // Show success message with data preview
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Data Export Ready'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your mood data (${moods.length} entries) is ready to export.',
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Preview:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      csvContent.toString().split('\n').take(5).join('\n'),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getMoodLabel(int mood) {
    switch (mood) {
      case 1:
        return 'Very Bad';
      case 2:
        return 'Bad';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance Section
            SettingsSectionWidget(
              title: 'Appearance',
              children: [
                ListTile(
                  leading: Icon(
                    _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    _isDarkMode ? 'Enabled' : 'Disabled',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                  trailing: Switch(
                    value: _isDarkMode,
                    onChanged: _toggleDarkMode,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Notifications Section
            SettingsSectionWidget(
              title: 'Notifications',
              children: [
                ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Daily Reminder'),
                  subtitle: Text(
                    _notificationsEnabled
                        ? 'Enabled at ${_notificationTime.format(context)}'
                        : 'Disabled',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                  ),
                ),
                if (_notificationsEnabled)
                  ListTile(
                    leading: Icon(
                      Icons.access_time,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: const Text('Reminder Time'),
                    subtitle: Text(
                      _notificationTime.format(context),
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectNotificationTime,
                  ),
              ],
            ),
            SizedBox(height: 2.h),

            // Data Management Section
            SettingsSectionWidget(
              title: 'Data Management',
              children: [
                ListTile(
                  leading: Icon(
                    Icons.download,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Export Data'),
                  subtitle: Text(
                    'Download your mood history as CSV',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportData,
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Reset All Data',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: Text(
                    'Permanently delete all mood entries',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showResetDialog,
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Legal Section
            SettingsSectionWidget(
              title: 'Legal',
              children: [
                ListTile(
                  leading: Icon(
                    Icons.privacy_tip,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Privacy Policy'),
                  subtitle: Text(
                    'How we handle your data',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.description,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Terms of Service'),
                  subtitle: Text(
                    'Terms and conditions',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.termsOfService);
                  },
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // App Info
            Center(
              child: Column(
                children: [
                  Text(
                    'MoodTap',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;

          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.home);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, AppRoutes.history);
              break;
            case 2:
              // Already on settings
              break;
          }
        },
      ),
    );
  }
}

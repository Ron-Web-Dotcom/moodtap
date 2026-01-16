import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
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

  /// Toggle notifications on/off
  Future<void> _toggleNotifications(bool value) async {
    try {
      final notificationService = NotificationService();

      if (value) {
        // Request permissions first
        final hasPermission = await notificationService.requestPermissions();
        if (!hasPermission) {
          // Permission denied
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
      }

      // Update theme without restarting the app - removing invalid type reference
      // Theme update will require app restart or proper state management implementation
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
      // Silent fail - show error in production
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appearance Section
                SettingsSectionWidget(
                  title: 'Appearance',
                  children: [_buildDarkModeToggle(theme)],
                ),
                const SizedBox(height: 24),

                // Notifications Section
                SettingsSectionWidget(
                  title: 'Notifications',
                  children: [
                    _buildNotificationToggle(theme),
                    if (_notificationsEnabled) ...[
                      const SizedBox(height: 12),
                      _buildNotificationTimePicker(theme),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Data Management Section
                SettingsSectionWidget(
                  title: 'Data Management',
                  children: [_buildResetDataButton(theme)],
                ),
                const SizedBox(height: 24),

                // About Section
                SettingsSectionWidget(
                  title: 'About',
                  children: [_buildAboutInfo(theme)],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  /// Build notification toggle switch
  Widget _buildNotificationToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: 'notifications',
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Reminder',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _notificationsEnabled ? 'Enabled' : 'Disabled',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  /// Build notification time picker
  Widget _buildNotificationTimePicker(ThemeData theme) {
    return InkWell(
      onTap: _selectNotificationTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'schedule',
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder Time',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _notificationTime.format(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  /// Build dark mode toggle switch
  Widget _buildDarkModeToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: _isDarkMode ? 'dark_mode' : 'light_mode',
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isDarkMode ? 'Enabled' : 'Disabled',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isDarkMode,
            onChanged: _toggleDarkMode,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  /// Build reset data button
  Widget _buildResetDataButton(ThemeData theme) {
    return InkWell(
      onTap: _showResetDialog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'warning',
                color: theme.colorScheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reset Data',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Delete all mood history',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Build about information section
  Widget _buildAboutInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'info',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'App Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(theme, 'Version', '1.0.0'),
          const SizedBox(height: 12),
          _buildInfoRow(theme, 'Build', '2026.01.03'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'lock',
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your mood data is stored locally on your device and never shared',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build information row
  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

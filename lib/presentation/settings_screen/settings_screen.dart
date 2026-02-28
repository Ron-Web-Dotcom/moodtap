import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/reset_data_dialog_widget.dart';

/// Settings screen with modern premium UI
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _currentIndex = 2;
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
    } catch (e) {}
  }

  Future<void> _showPermissionDeniedDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Permission Required'),
        content: const Text(
          'MoodTap needs notification permission to send you daily reminders. Please enable notifications in your device settings.',
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

  Future<void> _toggleNotifications(bool value) async {
    try {
      final notificationService = NotificationService();
      if (value) {
        final isPermanentlyDenied = await notificationService
            .isPermissionPermanentlyDenied();
        if (isPermanentlyDenied) {
          await _showPermissionDeniedDialog();
          return;
        }
        final hasPermission = await notificationService.requestPermissions();
        if (!hasPermission) {
          await _showPermissionDeniedDialog();
          return;
        }
        await notificationService.scheduleDailyReminder(
          _notificationTime.hour,
          _notificationTime.minute,
        );
      } else {
        await notificationService.cancelDailyReminder();
      }
      if (mounted) setState(() => _notificationsEnabled = value);
    } catch (e) {}
  }

  Future<void> _selectNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked != null && picked != _notificationTime) {
      if (mounted) setState(() => _notificationTime = picked);
      if (_notificationsEnabled) {
        try {
          await NotificationService().scheduleDailyReminder(
            picked.hour,
            picked.minute,
          );
        } catch (e) {}
      }
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', value);
      if (mounted) {
        setState(() => _isDarkMode = value);
        final myAppState = context
            .findRootAncestorStateOfType<State<StatefulWidget>>();
        if (myAppState != null) {
          final dynamic appState = myAppState;
          if (appState.runtimeType.toString() == '_MyAppState') {
            try {
              (appState as dynamic).updateThemeMode(value);
            } catch (e) {}
          }
        }
      }
    } catch (e) {}
  }

  Future<void> _showResetDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ResetDataDialogWidget(),
    );
    if (result == true && mounted) await _resetAllData();
  }

  Future<void> _resetAllData() async {
    try {
      try {
        await SupabaseService.instance.deleteAllMoods();
      } catch (e) {}
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool('isDarkMode') ?? false;
      await prefs.clear();
      await prefs.setBool('isDarkMode', isDarkMode);
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
                        : [const Color(0xFF2196F3), const Color(0xFF1565C0)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customize your experience',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'Settings',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Appearance', isDark),
                    const SizedBox(height: 10),
                    _buildSettingsCard(
                      isDark,
                      children: [
                        _buildSwitchTile(
                          icon: Icons.dark_mode_rounded,
                          iconColor: const Color(0xFF7C3AED),
                          title: 'Dark Mode',
                          subtitle: 'Switch to dark theme',
                          value: _isDarkMode,
                          onChanged: _toggleDarkMode,
                          isDark: isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionLabel('Notifications', isDark),
                    const SizedBox(height: 10),
                    _buildSettingsCard(
                      isDark,
                      children: [
                        _buildSwitchTile(
                          icon: Icons.notifications_rounded,
                          iconColor: const Color(0xFF2196F3),
                          title: 'Daily Reminders',
                          subtitle: 'Get reminded to log your mood',
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                          isDark: isDark,
                        ),
                        if (_notificationsEnabled)
                          ..._buildDividerAndTile(
                            _buildTapTile(
                              icon: Icons.access_time_rounded,
                              iconColor: const Color(0xFF00BCD4),
                              title: 'Reminder Time',
                              subtitle: _notificationTime.format(context),
                              onTap: _selectNotificationTime,
                              isDark: isDark,
                            ),
                            isDark,
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionLabel('Data & Privacy', isDark),
                    const SizedBox(height: 10),
                    _buildSettingsCard(
                      isDark,
                      children: [
                        _buildTapTile(
                          icon: Icons.privacy_tip_rounded,
                          iconColor: const Color(0xFF4CAF50),
                          title: 'Privacy Policy',
                          subtitle: 'How we handle your data',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.privacyPolicy,
                          ),
                          isDark: isDark,
                          showArrow: true,
                        ),
                        ..._buildDividerAndTile(
                          _buildTapTile(
                            icon: Icons.description_rounded,
                            iconColor: const Color(0xFF2196F3),
                            title: 'Terms of Service',
                            subtitle: 'Our terms and conditions',
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.termsOfService,
                            ),
                            isDark: isDark,
                            showArrow: true,
                          ),
                          isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionLabel('Danger Zone', isDark),
                    const SizedBox(height: 10),
                    _buildSettingsCard(
                      isDark,
                      children: [
                        _buildTapTile(
                          icon: Icons.delete_forever_rounded,
                          iconColor: const Color(0xFFEF5350),
                          title: 'Reset All Data',
                          subtitle: 'Permanently delete all mood entries',
                          onTap: _showResetDialog,
                          isDark: isDark,
                          titleColor: const Color(0xFFEF5350),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildAppVersion(isDark),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2196F3),
          ),
        ],
      ),
    );
  }

  Widget _buildTapTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool showArrow = false,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          titleColor ??
                          (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              showArrow
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : const Color(0xFFD1D5DB),
              size: showArrow ? 14 : 20,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDividerAndTile(Widget tile, bool isDark) {
    return [
      Divider(
        height: 1,
        indent: 70,
        endIndent: 16,
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F4F8),
      ),
      tile,
    ];
  }

  Widget _buildAppVersion(bool isDark) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text('😊', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'MoodTap',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

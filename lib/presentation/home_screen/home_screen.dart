import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/mood_emoji_button_widget.dart';
import './widgets/motivational_text_widget.dart';

/// Home screen for daily mood tracking with emoji selection
/// Allows users to log their mood once per day with haptic feedback
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBottomNavIndex = 0;
  int? _selectedMoodIndex;
  bool _isMoodLogged = false;
  bool _isLoading = true;
  String _todayDate = '';

  // Mood emoji data with labels
  final List<Map<String, dynamic>> _moodEmojis = [
    {'emoji': '😢', 'label': 'Very Sad', 'value': 1},
    {'emoji': '😕', 'label': 'Sad', 'value': 2},
    {'emoji': '😐', 'label': 'Neutral', 'value': 3},
    {'emoji': '🙂', 'label': 'Happy', 'value': 4},
    {'emoji': '😄', 'label': 'Very Happy', 'value': 5},
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  /// Validate mood entry structure and data integrity
  bool _isValidMoodEntry(dynamic item) {
    if (item is! Map) return false;
    if (!item.containsKey('date') || !item.containsKey('mood')) return false;
    if (item['date'] is! String) return false;

    // Accept both int and num (includes double) from JSON decoding
    final moodValue = item['mood'];
    if (moodValue is! num) return false;

    final mood = moodValue.toInt();
    return mood >= 1 && mood <= 5;
  }

  /// Initialize screen by checking if mood is already logged today
  Future<void> _initializeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _todayDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    final lastLoggedDate = prefs.getString('last_logged_date');
    final savedMood = prefs.getInt('today_mood');

    if (mounted) {
      setState(() {
        if (lastLoggedDate == today && savedMood != null) {
          _isMoodLogged = true;
          _selectedMoodIndex = savedMood - 1;
        }
        _isLoading = false;
      });
    }
  }

  /// Handle mood selection with haptic feedback and save to SharedPreferences
  Future<void> _onMoodSelected(int index) async {
    if (mounted) {
      setState(() {
        _selectedMoodIndex = index;
      });
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final moodValue = _moodEmojis[index]['value'] as int;

    // Save to Supabase first
    try {
      await SupabaseService.instance.saveMood(
        date: today,
        moodValue: moodValue,
      );
    } catch (e) {
      // If Supabase fails, continue with local backup
      debugPrint('Supabase save failed, using local backup: $e');
    }

    // Keep SharedPreferences as backup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_logged_date', today);
    await prefs.setInt('today_mood', moodValue);

    // Get existing mood history and save as JSON with robust error handling
    List<Map<String, dynamic>> moodHistory = [];

    try {
      final moodHistoryJson = prefs.getString('mood_history');

      if (moodHistoryJson != null && moodHistoryJson.isNotEmpty) {
        final List<dynamic> parsedHistory = json.decode(moodHistoryJson);

        // Convert to proper format with schema validation
        moodHistory = parsedHistory
            .where(_isValidMoodEntry)
            .map(
              (item) => {
                'date': item['date'] as String,
                // Ensure mood is stored as int, accepting num from JSON
                'mood': (item['mood'] as num).toInt(),
              },
            )
            .toList();
      }
    } catch (e) {
      // Parsing failed - start with empty list
      moodHistory = [];
    }

    // Check if today's mood already exists and update it, otherwise add new entry
    final existingIndex = moodHistory.indexWhere(
      (entry) => entry['date'] == today,
    );

    if (existingIndex != -1) {
      moodHistory[existingIndex] = {'date': today, 'mood': moodValue};
    } else {
      moodHistory.add({'date': today, 'mood': moodValue});
    }

    // Save the updated history with backup mechanism
    try {
      // Create backup before write
      final backupKey = 'mood_history_backup';
      final currentData = prefs.getString('mood_history');
      if (currentData != null) {
        await prefs.setString(backupKey, currentData);
      }

      // Attempt write with rollback capability
      final encodedHistory = json.encode(moodHistory);
      await prefs.setString('mood_history', encodedHistory);

      // Secondary backup: Store individual mood entries as fallback
      await prefs.setString(
        'mood_${today}',
        json.encode({'date': today, 'mood': moodValue}),
      );
    } catch (e) {
      // Critical: encoding failed, restore from backup
      final backupData = prefs.getString('mood_history_backup');
      if (backupData != null) {
        try {
          await prefs.setString('mood_history', backupData);
        } catch (_) {
          // Backup restore failed - keep today's mood separately
          await prefs.setString('last_logged_date', today);
          await prefs.setInt('today_mood', moodValue);
        }
      }
    }

    // Show confirmation animation
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _isMoodLogged = true;
      });
    }

    // Show success feedback
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.lightImpact();
                  await _initializeScreen();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Date display
                        Text(
                          _todayDate,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Main heading
                        Text(
                          _isMoodLogged
                              ? 'Today\'s Mood Logged!'
                              : 'How do you feel today?',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // Emoji buttons
                        _buildEmojiButtons(theme),

                        const SizedBox(height: 48),

                        // Completion message or motivational text
                        if (_isMoodLogged)
                          _buildCompletionMessage(theme)
                        else
                          const MotivationalTextWidget(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() {
            _currentBottomNavIndex = index;
          });
        },
      ),
    );
  }

  /// Build emoji selection buttons
  Widget _buildEmojiButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _moodEmojis.length,
          (index) => MoodEmojiButtonWidget(
            emoji: _moodEmojis[index]['emoji'] as String,
            label: _moodEmojis[index]['label'] as String,
            isSelected: _selectedMoodIndex == index,
            isDisabled: _isMoodLogged && _selectedMoodIndex != index,
            onTap: () => _onMoodSelected(index),
          ),
        ),
      ),
    );
  }

  /// Build completion message after mood is logged
  Widget _buildCompletionMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'check_circle',
            color: theme.colorScheme.primary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'See you tomorrow!',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your mood has been saved. Come back tomorrow to track your next mood.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

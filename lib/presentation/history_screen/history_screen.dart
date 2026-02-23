import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../widgets/custom_bottom_bar.dart';
import './widgets/monthly_view_widget.dart';
import './widgets/mood_detail_sheet.dart';
import './widgets/weekly_view_widget.dart';
import '../../services/supabase_service.dart';

/// History Screen - Displays mood tracking history with weekly and monthly views
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  List<Map<String, dynamic>> _allMoods = [];
  bool _isLoading = true;
  bool _isLoadingData = false; // Prevent concurrent loads
  int _currentBottomNavIndex = 1; // History tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _loadMoodData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only reload on app resume - prevents excessive SharedPreferences reads
    if (state == AppLifecycleState.resumed) {
      _loadMoodData();
    }
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

  Future<void> _loadMoodData() async {
    if (_isLoadingData || !mounted)
      return; // Prevent concurrent loads and disposed widget access
    _isLoadingData = true;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Try loading from Supabase first
      try {
        final supabaseMoods = await SupabaseService.instance.loadMoods();

        if (mounted) {
          setState(() {
            _allMoods = supabaseMoods
                .where(_isValidMoodEntry)
                .map(
                  (item) => {
                    'date': item['date'] as String,
                    'mood': (item['mood'] as num).toInt(),
                  },
                )
                .toList();
            _isLoading = false;
          });
          _isLoadingData = false;
          return;
        }
      } catch (e) {
        debugPrint('Supabase load failed, falling back to local: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Loading from local storage'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final moodsJson = prefs.getString('mood_history');

      if (moodsJson == null || moodsJson.isEmpty) {
        // Try to recover from individual backup entries
        await _recoverFromBackups(prefs);
        _isLoadingData = false;
        return;
      }

      try {
        final List<dynamic> moodsList = json.decode(moodsJson);

        if (mounted) {
          setState(() {
            // Apply schema validation to prevent corrupted data
            _allMoods = moodsList
                .where(_isValidMoodEntry)
                .map(
                  (item) => {
                    'date': item['date'] as String,
                    // Ensure mood is stored as int, accepting num from JSON
                    'mood': (item['mood'] as num).toInt(),
                  },
                )
                .toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        // JSON parsing failed - try to recover from backups
        await _recoverFromBackups(prefs);
      }
    } catch (e) {
      // Keep existing data if reload fails
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load mood data. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      _isLoadingData = false;
    }
  }

  /// Recover mood data from individual backup entries
  Future<void> _recoverFromBackups(SharedPreferences prefs) async {
    final recoveredMoods = <Map<String, dynamic>>[];
    final allKeys = prefs.getKeys();

    // Look for individual mood backup entries (format: mood_yyyy-MM-dd)
    for (final key in allKeys) {
      if (key.startsWith('mood_') &&
          key != 'mood_history' &&
          key != 'mood_history_backup') {
        try {
          final moodJson = prefs.getString(key);
          if (moodJson != null) {
            final moodData = json.decode(moodJson);
            if (_isValidMoodEntry(moodData)) {
              recoveredMoods.add({
                'date': moodData['date'] as String,
                'mood': (moodData['mood'] as num).toInt(),
              });
            }
          }
        } catch (e) {
          // Skip corrupted individual entries
          continue;
        }
      }
    }

    // Sort by date
    recoveredMoods.sort(
      (a, b) => (a['date'] as String).compareTo(b['date'] as String),
    );

    // Restore main history from recovered data
    if (recoveredMoods.isNotEmpty) {
      try {
        final encodedHistory = json.encode(recoveredMoods);
        await prefs.setString('mood_history', encodedHistory);
      } catch (e) {
        // Encoding failed, keep in memory only
      }
    }

    if (mounted) {
      setState(() {
        _allMoods = recoveredMoods;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getWeeklyMoods() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 6));

    // Generate list of date strings for the last 7 days
    final validDateStrings = List.generate(7, (index) {
      final date = startDate.add(Duration(days: index));
      return DateFormat('yyyy-MM-dd').format(date);
    }).toSet();

    return _allMoods.where((mood) {
      try {
        final dateStr = mood['date'] as String;
        // Direct string comparison against valid date range
        return validDateStrings.contains(dateStr);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<Map<String, dynamic>> _getMonthlyMoods() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    return _allMoods.where((mood) {
      try {
        final dateStr = mood['date'] as String;
        // Parse date string and compare month/year
        final parts = dateStr.split('-');
        if (parts.length != 3) return false;

        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);

        return month == currentMonth && year == currentYear;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  void _showMoodDetail(Map<String, dynamic> moodData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MoodDetailSheet(moodData: moodData),
    );
  }

  Future<void> _handleRefresh() async {
    await _loadMoodData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mood History'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: theme.colorScheme.primary,
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: WeeklyViewWidget(
                      weeklyMoods: _getWeeklyMoods(),
                      onMoodTap: _showMoodDetail,
                    ),
                  ),
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: MonthlyViewWidget(
                      monthlyMoods: _getMonthlyMoods(),
                      onMoodTap: _showMoodDetail,
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() => _currentBottomNavIndex = index);
        },
      ),
    );
  }
}

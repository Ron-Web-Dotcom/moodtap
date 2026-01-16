import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/custom_bottom_bar.dart';
import './widgets/monthly_view_widget.dart';
import './widgets/mood_detail_sheet.dart';
import './widgets/weekly_view_widget.dart';

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
  void didUpdateWidget(HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data whenever widget rebuilds (e.g., when navigating back to this screen)
    _loadMoodData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when dependencies change (e.g., when screen becomes visible)
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
    if (state == AppLifecycleState.resumed) {
      _loadMoodData();
    }
  }

  Future<void> _loadMoodData() async {
    if (_isLoadingData) return; // Prevent concurrent loads
    _isLoadingData = true;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final moodsJson = prefs.getString('mood_history');

      if (moodsJson == null || moodsJson.isEmpty) {
        if (mounted) {
          setState(() {
            _allMoods = [];
            _isLoading = false;
          });
        }
        _isLoadingData = false;
        return;
      }

      try {
        final List<dynamic> moodsList = json.decode(moodsJson);

        if (mounted) {
          setState(() {
            _allMoods = moodsList
                .map(
                  (item) => {
                    'date': item['date'] as String,
                    'mood': item['mood'] as int,
                  },
                )
                .toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        // JSON parsing failed - reset to empty list
        if (mounted) {
          setState(() {
            _allMoods = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Keep existing data if reload fails
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      _isLoadingData = false;
    }
  }

  List<Map<String, dynamic>> _getWeeklyMoods() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 6));

    return _allMoods.where((mood) {
      try {
        final dateStr = mood['date'] as String;
        final date = DateTime.parse(dateStr);
        final normalizedDate = DateTime(date.year, date.month, date.day);

        // Use compareTo for inclusive range check: startDate <= normalizedDate <= today
        return normalizedDate.compareTo(startDate) >= 0 &&
            normalizedDate.compareTo(today) <= 0;
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
        final date = DateTime.parse(dateStr);

        return date.month == currentMonth && date.year == currentYear;
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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../widgets/custom_bottom_bar.dart';
import './widgets/monthly_view_widget.dart';
import './widgets/mood_detail_sheet.dart';
import './widgets/weekly_view_widget.dart';
import '../../services/supabase_service.dart';

/// History Screen with modern premium UI
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
  bool _isLoadingData = false;
  int _currentBottomNavIndex = 1;

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
    if (state == AppLifecycleState.resumed) _loadMoodData();
  }

  bool _isValidMoodEntry(dynamic item) {
    if (item is! Map) return false;
    if (!item.containsKey('date') || !item.containsKey('mood')) return false;
    if (item['date'] is! String) return false;
    final moodValue = item['mood'];
    if (moodValue is! num) return false;
    final mood = moodValue.toInt();
    return mood >= 1 && mood <= 5;
  }

  Future<void> _loadMoodData() async {
    if (_isLoadingData || !mounted) return;
    _isLoadingData = true;
    if (mounted) setState(() => _isLoading = true);

    try {
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
        debugPrint('Supabase load failed: $e');
      }

      final prefs = await SharedPreferences.getInstance();
      final moodsJson = prefs.getString('mood_history');

      if (moodsJson == null || moodsJson.isEmpty) {
        await _recoverFromBackups(prefs);
        _isLoadingData = false;
        return;
      }

      try {
        final List<dynamic> moodsList = json.decode(moodsJson);
        if (mounted) {
          setState(() {
            _allMoods = moodsList
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
        }
      } catch (e) {
        await _recoverFromBackups(prefs);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    } finally {
      _isLoadingData = false;
    }
  }

  Future<void> _recoverFromBackups(SharedPreferences prefs) async {
    final recoveredMoods = <Map<String, dynamic>>[];
    final allKeys = prefs.getKeys();
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
          continue;
        }
      }
    }
    recoveredMoods.sort(
      (a, b) => (a['date'] as String).compareTo(b['date'] as String),
    );
    if (recoveredMoods.isNotEmpty) {
      try {
        await prefs.setString('mood_history', json.encode(recoveredMoods));
      } catch (e) {}
    }
    if (mounted)
      setState(() {
        _allMoods = recoveredMoods;
        _isLoading = false;
      });
  }

  List<Map<String, dynamic>> _getWeeklyMoods() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 6));
    final validDateStrings = List.generate(7, (index) {
      final date = startDate.add(Duration(days: index));
      return DateFormat('yyyy-MM-dd').format(date);
    }).toSet();
    return _allMoods.where((mood) {
      try {
        return validDateStrings.contains(mood['date'] as String);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<Map<String, dynamic>> _getMonthlyMoods() {
    final now = DateTime.now();
    return _allMoods.where((mood) {
      try {
        final parts = (mood['date'] as String).split('-');
        if (parts.length != 3) return false;
        return int.parse(parts[1]) == now.month &&
            int.parse(parts[0]) == now.year;
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
            expandedHeight: 160,
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
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mood History',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_allMoods.length} total entries',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
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
              'History',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFF2196F3),
                  unselectedLabelColor: isDark
                      ? Colors.white60
                      : Colors.white70,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: const [
                    Tab(text: 'Weekly'),
                    Tab(text: 'Monthly'),
                  ],
                ),
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
            : RefreshIndicator(
                onRefresh: _loadMoodData,
                color: theme.colorScheme.primary,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: WeeklyViewWidget(
                        weeklyMoods: _getWeeklyMoods(),
                        onMoodTap: _showMoodDetail,
                      ),
                    ),
                    SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: MonthlyViewWidget(
                        monthlyMoods: _getMonthlyMoods(),
                        onMoodTap: _showMoodDetail,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) => setState(() => _currentBottomNavIndex = index),
      ),
    );
  }
}

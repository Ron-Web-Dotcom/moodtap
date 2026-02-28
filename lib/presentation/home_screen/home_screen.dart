import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/mood_emoji_button_widget.dart';
import './widgets/motivational_text_widget.dart';

/// Home screen for daily mood tracking with modern premium UI
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentBottomNavIndex = 0;
  int? _selectedMoodIndex;
  bool _isMoodLogged = false;
  bool _isLoading = true;
  String _todayDate = '';
  late AnimationController _headerAnimController;
  late AnimationController _cardAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _cardSlide;

  final List<Map<String, dynamic>> _moodEmojis = [
    {
      'emoji': '😢',
      'label': 'Very Sad',
      'value': 1,
      'color': Color(0xFFEF5350),
      'bgColor': Color(0xFFFFEBEE),
    },
    {
      'emoji': '😕',
      'label': 'Sad',
      'value': 2,
      'color': Color(0xFFFF9800),
      'bgColor': Color(0xFFFFF3E0),
    },
    {
      'emoji': '😐',
      'label': 'Neutral',
      'value': 3,
      'color': Color(0xFFFFC107),
      'bgColor': Color(0xFFFFFDE7),
    },
    {
      'emoji': '🙂',
      'label': 'Happy',
      'value': 4,
      'color': Color(0xFF66BB6A),
      'bgColor': Color(0xFFE8F5E9),
    },
    {
      'emoji': '😄',
      'label': 'Very Happy',
      'value': 5,
      'color': Color(0xFF2196F3),
      'bgColor': Color(0xFFE3F2FD),
    },
  ];

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _cardAnimController,
            curve: Curves.easeOutCubic,
          ),
        );
    _initializeScreen();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _cardAnimController.dispose();
    super.dispose();
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

  Future<void> _initializeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _todayDate = DateFormat('EEEE, MMMM d').format(DateTime.now());

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
      _headerAnimController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _cardAnimController.forward();
    }
  }

  Future<void> _onMoodSelected(int index) async {
    if (_isMoodLogged) return;
    HapticFeedback.selectionClick();
    if (mounted) setState(() => _selectedMoodIndex = index);

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final moodValue = _moodEmojis[index]['value'] as int;

    bool supabaseSaveSuccess = false;
    try {
      await SupabaseService.instance.saveMood(
        date: today,
        moodValue: moodValue,
      );
      supabaseSaveSuccess = true;
    } catch (e) {
      debugPrint('Supabase save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved locally. Will sync when online.'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_logged_date', today);
    await prefs.setInt('today_mood', moodValue);

    List<Map<String, dynamic>> moodHistory = [];
    try {
      final moodHistoryJson = prefs.getString('mood_history');
      if (moodHistoryJson != null && moodHistoryJson.isNotEmpty) {
        final List<dynamic> parsedHistory = json.decode(moodHistoryJson);
        moodHistory = parsedHistory
            .where(_isValidMoodEntry)
            .map(
              (item) => {
                'date': item['date'] as String,
                'mood': (item['mood'] as num).toInt(),
              },
            )
            .toList();
      }
    } catch (e) {
      moodHistory = [];
    }

    final existingIndex = moodHistory.indexWhere(
      (entry) => entry['date'] == today,
    );
    if (existingIndex != -1) {
      moodHistory[existingIndex] = {'date': today, 'mood': moodValue};
    } else {
      moodHistory.add({'date': today, 'mood': moodValue});
    }

    try {
      final backupKey = 'mood_history_backup';
      final currentData = prefs.getString('mood_history');
      if (currentData != null) await prefs.setString(backupKey, currentData);
      await prefs.setString('mood_history', json.encode(moodHistory));
      await prefs.setString(
        'mood_$today',
        json.encode({'date': today, 'mood': moodValue}),
      );
    } catch (e) {
      final backupData = prefs.getString('mood_history_backup');
      if (backupData != null) {
        try {
          await prefs.setString('mood_history', backupData);
        } catch (_) {}
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _isMoodLogged = true);

    HapticFeedback.mediumImpact();
    if (mounted && supabaseSaveSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mood saved! ✨'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Color _getSelectedMoodColor() {
    if (_selectedMoodIndex == null) return const Color(0xFF2196F3);
    return _moodEmojis[_selectedMoodIndex!]['color'] as Color;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: _isLoading
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
              color: theme.colorScheme.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildSliverHeader(theme, isDark),
                  SliverToBoxAdapter(
                    child: SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _headerFade,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              _buildMoodSelectionCard(theme, isDark),
                              const SizedBox(height: 20),
                              if (_isMoodLogged)
                                _buildCompletionCard(theme, isDark)
                              else
                                _buildMotivationalCard(theme, isDark),
                              const SizedBox(height: 20),
                              _buildQuickStatsCard(theme, isDark),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) => setState(() => _currentBottomNavIndex = index),
      ),
    );
  }

  Widget _buildSliverHeader(ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: FadeTransition(
          opacity: _headerFade,
          child: Container(
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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _todayDate,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isMoodLogged
                          ? 'Mood Logged! 🎉'
                          : 'How are you\nfeeling today?',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          'MoodTap',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelectionCard(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF2196F3).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isMoodLogged
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF2196F3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isMoodLogged ? 'Today\'s mood' : 'Select your mood',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                if (_isMoodLogged && _selectedMoodIndex != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (_moodEmojis[_selectedMoodIndex!]['bgColor']
                              as Color),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _moodEmojis[_selectedMoodIndex!]['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            _moodEmojis[_selectedMoodIndex!]['color'] as Color,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                _moodEmojis.length,
                (index) => _buildMoodCard(index, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCard(int index, bool isDark) {
    final mood = _moodEmojis[index];
    final isSelected = _selectedMoodIndex == index;
    final isDisabled = _isMoodLogged && !isSelected;
    final moodColor = mood['color'] as Color;
    final moodBgColor = mood['bgColor'] as Color;

    return Semantics(
      label: '${mood['label']} mood',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: isDisabled ? null : () => _onMoodSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 56,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: isSelected ? 56 : 50,
                height: isSelected ? 56 : 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? moodBgColor
                      : isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(isSelected ? 18 : 16),
                  border: isSelected
                      ? Border.all(color: moodColor, width: 2)
                      : Border.all(color: Colors.transparent),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: moodColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isDisabled ? 0.3 : 1.0,
                    child: Text(
                      mood['emoji'] as String,
                      style: TextStyle(fontSize: isSelected ? 28 : 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isDisabled ? 0.3 : 1.0,
                child: Text(
                  (mood['label'] as String).split(' ').last,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? moodColor
                        : (isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCard(ThemeData theme, bool isDark) {
    final moodColor = _getSelectedMoodColor();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [moodColor, moodColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: moodColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Icon(Icons.check_rounded, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Great job! 🌟',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Come back tomorrow to continue your streak.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalCard(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFBBDEFB),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Text('💡', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Take a moment to reflect on your feelings. Your emotions matter.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : const Color(0xFF1565C0),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF2196F3).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Journey',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(
                  '📅',
                  'Today',
                  _isMoodLogged ? 'Logged' : 'Pending',
                  isDark,
                ),
                _buildStatDivider(isDark),
                _buildStatItem('🔥', 'Streak', '1 day', isDark),
                _buildStatDivider(isDark),
                _buildStatItem('📊', 'History', 'View all', isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 40,
      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8EDF2),
    );
  }
}

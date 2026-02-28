import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Weekly mood history with modern card-based design
class WeeklyViewWidget extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyMoods;
  final Function(Map<String, dynamic>) onMoodTap;

  const WeeklyViewWidget({
    super.key,
    required this.weeklyMoods,
    required this.onMoodTap,
  });

  Color _getMoodColor(int moodValue) {
    switch (moodValue) {
      case 1:
        return const Color(0xFFEF5350);
      case 2:
        return const Color(0xFFFF9800);
      case 3:
        return const Color(0xFFFFC107);
      case 4:
        return const Color(0xFF66BB6A);
      case 5:
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  String _getMoodEmoji(int moodValue) {
    switch (moodValue) {
      case 1:
        return '😢';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '❓';
    }
  }

  String _getMoodLabel(int moodValue) {
    switch (moodValue) {
      case 1:
        return 'Very Sad';
      case 2:
        return 'Sad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Happy';
      case 5:
        return 'Very Happy';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 6));

    final Map<String, int> moodMap = {};
    for (var mood in weeklyMoods) {
      try {
        moodMap[mood['date'] as String] = mood['mood'] as int;
      } catch (e) {}
    }

    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final moodValue = moodMap[dateStr] ?? 0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: moodValue > 0 ? moodValue.toDouble() : 0,
              color: moodValue > 0
                  ? _getMoodColor(moodValue)
                  : (isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFEEF2F7)),
              width: 28,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary stats row
        Row(
          children: [
            _buildStatChip(
              '${weeklyMoods.length}/7',
              'Days logged',
              const Color(0xFF2196F3),
              isDark,
            ),
            const SizedBox(width: 12),
            if (weeklyMoods.isNotEmpty)
              _buildStatChip(
                _getMoodEmoji(_getAverageMood()),
                'Avg mood',
                const Color(0xFF66BB6A),
                isDark,
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Chart card
        Container(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Last 7 Days',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      '${DateFormat('MMM d').format(startDate)} – ${DateFormat('MMM d').format(today)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (weeklyMoods.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: Semantics(
                      label:
                          'Weekly mood bar chart with ${weeklyMoods.length} entries',
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 5,
                          minY: 0,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFF1A1A2E),
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    final date = startDate.add(
                                      Duration(days: group.x.toInt()),
                                    );
                                    final moodValue = rod.toY.toInt();
                                    if (moodValue == 0) return null;
                                    return BarTooltipItem(
                                      '${DateFormat('EEE').format(date)}\n',
                                      GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: _getMoodLabel(moodValue),
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final date = startDate.add(
                                    Duration(days: value.toInt()),
                                  );
                                  final isToday =
                                      DateFormat('yyyy-MM-dd').format(date) ==
                                      DateFormat('yyyy-MM-dd').format(now);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      DateFormat(
                                        'E',
                                      ).format(date).substring(0, 1),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: isToday
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: isToday
                                            ? const Color(0xFF2196F3)
                                            : (isDark
                                                  ? Colors.white54
                                                  : const Color(0xFF9CA3AF)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFF0F4F8),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: barGroups,
                        ),
                      ),
                    ),
                  )
                else
                  _buildEmptyState(isDark),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Daily entries list
        if (weeklyMoods.isNotEmpty)
          ..._buildDailyEntries(isDark, moodMap, startDate),
      ],
    );
  }

  int _getAverageMood() {
    if (weeklyMoods.isEmpty) return 3;
    final total = weeklyMoods.fold<int>(
      0,
      (sum, m) => sum + (m['mood'] as int),
    );
    return (total / weeklyMoods.length).round();
  }

  Widget _buildStatChip(String value, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDailyEntries(
    bool isDark,
    Map<String, int> moodMap,
    DateTime startDate,
  ) {
    final widgets = <Widget>[];
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          'Daily Breakdown',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ),
    );

    for (int i = 6; i >= 0; i--) {
      final date = startDate.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final moodValue = moodMap[dateStr];
      if (moodValue == null) continue;

      final moodColor = _getMoodColor(moodValue);
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: moodColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _getMoodEmoji(moodValue),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            title: Text(
              DateFormat('EEEE').format(date),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            subtitle: Text(
              DateFormat('MMM d').format(date),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: moodColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getMoodLabel(moodValue),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: moodColor,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Text('📊', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No moods logged this week',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start tracking your mood today!',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
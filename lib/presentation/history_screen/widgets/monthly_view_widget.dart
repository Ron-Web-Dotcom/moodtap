import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Monthly mood history with modern card-based design
class MonthlyViewWidget extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyMoods;
  final Function(Map<String, dynamic>) onMoodTap;

  const MonthlyViewWidget({
    super.key,
    required this.monthlyMoods,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final Map<String, int> moodMap = {};
    for (var mood in monthlyMoods) {
      try {
        moodMap[mood['date'] as String] = mood['mood'] as int;
      } catch (e) {}
    }

    final List<BarChartGroupData> barGroups = [];
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final moodValue = moodMap[dateStr] ?? 0;
      barGroups.add(
        BarChartGroupData(
          x: day - 1,
          barRods: [
            BarChartRodData(
              toY: moodValue > 0 ? moodValue.toDouble() : 0,
              color: moodValue > 0
                  ? _getMoodColor(moodValue)
                  : (isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFEEF2F7)),
              width: daysInMonth > 28 ? 7 : 9,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary row
        Row(
          children: [
            _buildStatChip(
              '${monthlyMoods.length}',
              'Days logged',
              const Color(0xFF2196F3),
              isDark,
            ),
            const SizedBox(width: 12),
            _buildStatChip(
              '$daysInMonth',
              'Days in month',
              const Color(0xFF9C27B0),
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
                      DateFormat('MMMM yyyy').format(now),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${monthlyMoods.length} entries',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (monthlyMoods.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: Semantics(
                      label:
                          'Monthly mood chart with ${monthlyMoods.length} entries',
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
                                    final day = group.x.toInt() + 1;
                                    final date = DateTime(
                                      now.year,
                                      now.month,
                                      day,
                                    );
                                    final moodValue = rod.toY.toInt();
                                    if (moodValue == 0) return null;
                                    return BarTooltipItem(
                                      '${DateFormat('MMM d').format(date)}\n',
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
                                interval: daysInMonth > 28 ? 5 : 4,
                                getTitlesWidget: (value, meta) {
                                  final day = value.toInt() + 1;
                                  if (day == 1 ||
                                      day == 10 ||
                                      day == 20 ||
                                      day == daysInMonth) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        day.toString(),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white54
                                              : const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
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

        // Mood distribution
        if (monthlyMoods.isNotEmpty) _buildMoodDistribution(isDark),
      ],
    );
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
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistribution(bool isDark) {
    final moodCounts = <int, int>{};
    for (var mood in monthlyMoods) {
      final value = mood['mood'] as int;
      moodCounts[value] = (moodCounts[value] ?? 0) + 1;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Distribution',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(5, (i) {
              final moodValue = 5 - i;
              final count = moodCounts[moodValue] ?? 0;
              final percentage = monthlyMoods.isEmpty
                  ? 0.0
                  : count / monthlyMoods.length;
              final color = _getMoodColor(moodValue);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(
                      _getMoodEmoji(moodValue),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getMoodLabel(moodValue),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                              Text(
                                '$count days',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFF0F4F8),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Text('📈', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No moods logged this month',
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
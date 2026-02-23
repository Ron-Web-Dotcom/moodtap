import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Widget displaying monthly mood history as bar chart
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
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFFFBBF24);
      case 4:
        return const Color(0xFF10B981);
      case 5:
        return const Color(0xFF059669);
      default:
        return Colors.grey;
    }
  }

  String _getMoodLabel(int moodValue) {
    switch (moodValue) {
      case 1:
        return 'Very sad';
      case 2:
        return 'Sad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Happy';
      case 5:
        return 'Very happy';
      default:
        return 'Unknown';
    }
  }

  String _generateChartAccessibilityLabel() {
    if (monthlyMoods.isEmpty) {
      return 'Monthly mood chart. No mood entries for this month.';
    }

    final moodCounts = <int, int>{};
    for (var mood in monthlyMoods) {
      final value = mood['mood'] as int;
      moodCounts[value] = (moodCounts[value] ?? 0) + 1;
    }

    final description = StringBuffer(
      'Monthly mood chart with ${monthlyMoods.length} entries. ',
    );
    moodCounts.forEach((mood, count) {
      description.write('$count ${_getMoodLabel(mood)} days. ');
    });

    return description.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Create a map of date -> mood value for quick lookup
    final Map<String, int> moodMap = {};
    for (var mood in monthlyMoods) {
      try {
        final dateStr = mood['date'] as String;
        final moodValue = mood['mood'] as int;
        moodMap[dateStr] = moodValue;
      } catch (e) {
        // Skip invalid entries
      }
    }

    // Generate bar data for each day of the month
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
                  : theme.colorScheme.outline.withValues(alpha: 0.1),
              width: daysInMonth > 28 ? 8 : 10,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(now),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${monthlyMoods.length} mood entries',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          if (monthlyMoods.isNotEmpty)
            SizedBox(
              height: 280,
              child: Semantics(
                label: _generateChartAccessibilityLabel(),
                hint: 'Swipe to explore individual days',
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 5,
                    minY: 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final day = group.x.toInt() + 1;
                          final date = DateTime(now.year, now.month, day);
                          final dateStr = DateFormat('MMM d').format(date);
                          final moodValue = rod.toY.toInt();

                          if (moodValue == 0) return null;

                          return BarTooltipItem(
                            '$dateStr\n',
                            theme.textTheme.labelMedium!.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(
                                text: 'Mood: $moodValue',
                                style: theme.textTheme.labelSmall!.copyWith(
                                  color: Colors.white70,
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
                          interval: daysInMonth > 28 ? 5 : 3,
                          getTitlesWidget: (value, meta) {
                            final day = value.toInt() + 1;
                            if (day == 1 || day == 15 || day == daysInMonth) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  day.toString(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value == 5) {
                              return Text(
                                value.toInt().toString(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
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
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.1,
                          ),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
            ),
          if (monthlyMoods.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Semantics(
                    label: 'No mood entries',
                    child: Text('📈', style: const TextStyle(fontSize: 64)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No mood entries this month',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your mood daily to see trends',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (monthlyMoods.isNotEmpty) _buildMoodLegend(theme),
        ],
      ),
    );
  }

  Widget _buildMoodLegend(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Scale',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem(
                theme,
                '😢',
                'Very Sad',
                const Color(0xFFEF4444),
              ),
              _buildLegendItem(theme, '😕', 'Sad', const Color(0xFFF59E0B)),
              _buildLegendItem(theme, '😐', 'Neutral', const Color(0xFFFBBF24)),
              _buildLegendItem(theme, '🙂', 'Happy', const Color(0xFF10B981)),
              _buildLegendItem(
                theme,
                '😄',
                'Very Happy',
                const Color(0xFF059669),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    ThemeData theme,
    String emoji,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

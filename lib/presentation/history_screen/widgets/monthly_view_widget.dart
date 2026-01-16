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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Group moods by week
    final Map<int, List<Map<String, dynamic>>> weeklyGroups = {};
    for (var mood in monthlyMoods) {
      try {
        final dateStr = mood['date'] as String;
        final date = DateTime.parse(dateStr);
        final weekNumber = ((date.day - 1) / 7).floor();
        weeklyGroups.putIfAbsent(weekNumber, () => []);
        weeklyGroups[weekNumber]!.add(mood);
      } catch (e) {
        // Skip invalid date entries
      }
    }

    // Calculate average mood per week
    final List<double> weeklyAverages = [];
    for (int i = 0; i < 5; i++) {
      if (weeklyGroups.containsKey(i) && weeklyGroups[i]!.isNotEmpty) {
        final avg =
            weeklyGroups[i]!
                .map((m) => m['mood'] as int)
                .reduce((a, b) => a + b) /
            weeklyGroups[i]!.length;
        weeklyAverages.add(avg);
      } else {
        weeklyAverages.add(0);
      }
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
                label: 'Monthly Mood Bar Chart',
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 5,
                    minY: 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            'Week ${group.x + 1}\n',
                            theme.textTheme.labelMedium!.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(
                                text: 'Avg: ${rod.toY.toStringAsFixed(1)}',
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
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'W${value.toInt() + 1}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
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
                    barGroups: List.generate(
                      weeklyAverages.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: weeklyAverages[index],
                            color: weeklyAverages[index] > 0
                                ? _getMoodColor(weeklyAverages[index].round())
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                            width: 32,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (monthlyMoods.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text('📈', style: const TextStyle(fontSize: 64)),
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

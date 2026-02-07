import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Widget displaying weekly mood history as bar chart and colored dots
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
        return const Color(0xFFEF4444); // Very sad - red
      case 2:
        return const Color(0xFFF59E0B); // Sad - orange
      case 3:
        return const Color(0xFFFBBF24); // Neutral - yellow
      case 4:
        return const Color(0xFF10B981); // Happy - light green
      case 5:
        return const Color(0xFF059669); // Very happy - green
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate last 7 days including today
    final startDate = today.subtract(const Duration(days: 6));

    // Create mood map for quick lookup
    final Map<String, int> moodMap = {};
    for (var mood in weeklyMoods) {
      try {
        final dateStr = mood['date'] as String;
        final moodValue = mood['mood'] as int;
        moodMap[dateStr] = moodValue;
      } catch (e) {
        // Skip invalid entries
      }
    }

    // Generate bar chart data for 7 days
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
                  : theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 32,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
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
            'Last 7 Days',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, yyyy').format(today)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${weeklyMoods.length} mood entries',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Bar Chart
          if (weeklyMoods.isNotEmpty)
            SizedBox(
              height: 280,
              child: Semantics(
                label: 'Weekly Mood Bar Chart',
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 5,
                    minY: 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final date = startDate.add(
                            Duration(days: group.x.toInt()),
                          );
                          final dateStr = DateFormat('EEE, MMM d').format(date);
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
                          getTitlesWidget: (value, meta) {
                            final date = startDate.add(
                              Duration(days: value.toInt()),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('E').format(date).substring(0, 1),
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
                    barGroups: barGroups,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 32),

          // Day-by-day dots view
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = startDate.add(Duration(days: index));
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final mood = weeklyMoods.firstWhere(
                (m) => m['date'] == dateStr,
                orElse: () => {},
              );

              final hasMood = mood.isNotEmpty;
              final moodValue = hasMood ? mood['mood'] as int : 0;

              return Expanded(
                child: Semantics(
                  label: hasMood
                      ? '${DateFormat('EEEE, MMMM d').format(date)}, ${_getMoodLabel(moodValue)} mood'
                      : '${DateFormat('EEEE, MMMM d').format(date)}, no mood recorded',
                  button: hasMood,
                  enabled: hasMood,
                  child: GestureDetector(
                    onTap: hasMood ? () => onMoodTap(mood) : null,
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E').format(date).substring(0, 1),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasMood
                                ? Colors.transparent
                                : theme.colorScheme.surface,
                            border: Border.all(
                              color: hasMood
                                  ? _getMoodColor(moodValue)
                                  : theme.colorScheme.outline.withValues(
                                      alpha: 0.3,
                                    ),
                              width: 2,
                            ),
                            boxShadow: hasMood
                                ? [
                                    BoxShadow(
                                      color: _getMoodColor(
                                        moodValue,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              hasMood ? _getMoodEmoji(moodValue) : '',
                              style: const TextStyle(fontSize: 24, height: 1.0),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('d').format(date),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          if (weeklyMoods.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text('📊', style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'No mood entries this week',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking your mood to see patterns',
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
        ],
      ),
    );
  }
}

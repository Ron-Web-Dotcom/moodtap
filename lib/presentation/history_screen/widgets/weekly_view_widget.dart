import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget displaying weekly mood history as colored dots
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate last 7 days including today
    final startDate = today.subtract(const Duration(days: 6));

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
          const SizedBox(height: 32),
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

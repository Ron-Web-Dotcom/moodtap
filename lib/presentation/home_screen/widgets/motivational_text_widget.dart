import 'package:flutter/material.dart';

/// Widget displaying motivational text with accessibility support
class MotivationalTextWidget extends StatelessWidget {
  final String text;
  final bool isMoodLogged;

  const MotivationalTextWidget({
    super.key,
    required this.text,
    required this.isMoodLogged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: isMoodLogged
          ? 'Mood logged successfully. $text'
          : 'Motivational message: $text',
      readOnly: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

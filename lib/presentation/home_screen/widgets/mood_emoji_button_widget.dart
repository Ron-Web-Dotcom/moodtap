import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Individual mood emoji button with touch feedback and animations
class MoodEmojiButtonWidget extends StatefulWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const MoodEmojiButtonWidget({
    super.key,
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<MoodEmojiButtonWidget> createState() => _MoodEmojiButtonWidgetState();
}

class _MoodEmojiButtonWidgetState extends State<MoodEmojiButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController
        .stop(); // Stop animation before disposal to prevent memory leaks
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled) {
      setState(() => _isPressed = true);
      _animationController.forward();
      HapticFeedback.selectionClick();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isDisabled) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isDisabled) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.isSelected || (!widget.isDisabled && !_isPressed);

    return Semantics(
      label: '${widget.label} mood. ${widget.emoji}',
      hint: widget.isDisabled
          ? 'Already selected for today'
          : 'Double tap to select ${widget.label} mood',
      button: true,
      enabled: !widget.isDisabled,
      selected: widget.isSelected,
      onTap: widget.isDisabled ? null : widget.onTap,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isDisabled ? 1.0 : _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? (theme.colorScheme.primary.withValues(alpha: 0.1))
                      : widget.isDisabled
                      ? (theme.colorScheme.surface.withValues(alpha: 0.5))
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isSelected
                        ? theme.colorScheme.primary
                        : (theme.colorScheme.outline.withValues(alpha: 0.2)),
                    width: widget.isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: widget.isDisabled && !widget.isSelected
                        ? 0.3
                        : 1.0,
                    child: Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 32),
                      semanticsLabel: widget.label,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

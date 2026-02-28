import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/app_routes.dart';

/// Modern floating bottom navigation bar with clean design
class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const CustomBottomBar({super.key, required this.currentIndex, this.onTap});

  void _handleNavigation(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.history);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: 'Bottom navigation bar',
      container: true,
      explicitChildNodes: true,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : const Color(0xFF2196F3).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  0,
                  Icons.home_rounded,
                  Icons.home_outlined,
                  'Home',
                  isDark,
                ),
                _buildNavItem(
                  context,
                  1,
                  Icons.bar_chart_rounded,
                  Icons.bar_chart_outlined,
                  'History',
                  isDark,
                ),
                _buildNavItem(
                  context,
                  2,
                  Icons.settings_rounded,
                  Icons.settings_outlined,
                  'Settings',
                  isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    bool isDark,
  ) {
    final isSelected = currentIndex == index;

    return Semantics(
      label: isSelected ? '$label, selected' : label,
      button: true,
      child: GestureDetector(
        onTap: () => _handleNavigation(context, index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2196F3).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  key: ValueKey(isSelected),
                  color: isSelected
                      ? const Color(0xFF2196F3)
                      : (isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF2196F3)
                      : (isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

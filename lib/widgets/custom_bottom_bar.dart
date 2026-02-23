import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

/// Custom bottom navigation bar for the app with full accessibility support
class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const CustomBottomBar({super.key, required this.currentIndex, this.onTap});

  void _handleNavigation(BuildContext context, int index) {
    if (index == currentIndex) return;

    // Navigate to the appropriate screen
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

    return Semantics(
      label: 'Bottom navigation bar with three tabs',
      container: true,
      explicitChildNodes: true,
      child: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _handleNavigation(context, index),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurfaceVariant,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: Semantics(
                label: currentIndex == 0 ? 'Home, selected' : 'Home',
                button: true,
                child: Icon(Icons.home_outlined),
              ),
              activeIcon: Semantics(
                label: 'Home, selected',
                button: true,
                child: Icon(Icons.home),
              ),
              label: 'Home',
              tooltip: 'Navigate to home screen to log your mood',
            ),
            BottomNavigationBarItem(
              icon: Semantics(
                label: currentIndex == 1 ? 'History, selected' : 'History',
                button: true,
                child: Icon(Icons.history_outlined),
              ),
              activeIcon: Semantics(
                label: 'History, selected',
                button: true,
                child: Icon(Icons.history),
              ),
              label: 'History',
              tooltip: 'View mood history and charts',
            ),
            BottomNavigationBarItem(
              icon: Semantics(
                label: currentIndex == 2 ? 'Settings, selected' : 'Settings',
                button: true,
                child: Icon(Icons.settings_outlined),
              ),
              activeIcon: Semantics(
                label: 'Settings, selected',
                button: true,
                child: Icon(Icons.settings),
              ),
              label: 'Settings',
              tooltip: 'Open app settings and preferences',
            ),
          ],
        ),
      ),
    );
  }
}

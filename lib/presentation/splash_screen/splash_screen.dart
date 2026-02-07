import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Splash screen with branded launch experience and mood tracking initialization
/// Displays app logo with animation, checks user data, and navigates appropriately
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isInitializing = true;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Setup fade and scale animations for logo
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  /// Initialize app data and determine navigation path
  Future<void> _initializeApp() async {
    try {
      // Start animation
      setState(() {
        _statusMessage = 'Loading your moods...';
      });

      // Initialize SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Check for corrupted data
      final hasCorruptedData = await _checkDataIntegrity(prefs);
      if (hasCorruptedData) {
        await _handleCorruptedData(prefs);
        return;
      }

      // Load theme preference
      final isDarkMode = prefs.getBool('isDarkMode') ?? false;
      setState(() {
        _statusMessage = 'Applying theme...';
      });

      // Check if user has existing mood data
      final hasMoodData = prefs.containsKey('moodHistory');
      final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

      // Wait for minimum splash duration
      await Future.delayed(const Duration(milliseconds: 2000));

      // Navigate based on user state
      if (mounted) {
        if (isFirstLaunch || !hasMoodData) {
          // First time user - could show onboarding (for now go to home)
          await prefs.setBool('isFirstLaunch', false);
          Navigator.pushReplacementNamed(context, '/home-screen');
        } else {
          // Returning user with data
          Navigator.pushReplacementNamed(context, '/home-screen');
        }
      }
    } catch (e) {
      // Handle initialization errors gracefully
      if (mounted) {
        setState(() {
          _statusMessage = 'Starting fresh...';
        });
        await Future.delayed(const Duration(milliseconds: 1000));
        Navigator.pushReplacementNamed(context, '/home-screen');
      }
    }
  }

  /// Check data integrity for corruption
  Future<bool> _checkDataIntegrity(SharedPreferences prefs) async {
    try {
      // Try to read mood history
      final moodHistory = prefs.getString('moodHistory');
      if (moodHistory != null && moodHistory.isNotEmpty) {
        // Basic validation - check if it's valid data structure
        if (!moodHistory.startsWith('[') && !moodHistory.startsWith('{')) {
          return true; // Corrupted
        }
      }
      return false;
    } catch (e) {
      return true; // Error reading data = corrupted
    }
  }

  /// Handle corrupted data with user dialog
  Future<void> _handleCorruptedData(SharedPreferences prefs) async {
    if (!mounted) return;

    final shouldReset = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Data Issue Detected'),
        content: const Text(
          'We found an issue with your mood data. Would you like to reset and start fresh?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset Data'),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      await prefs.clear();
      await prefs.setBool('isFirstLaunch', false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home-screen');
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home-screen');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.colorScheme.secondary.withValues(alpha: 0.05),
                    theme.colorScheme.surface,
                  ]
                : [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
                    theme.scaffoldBackgroundColor,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated logo section
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildLogoSection(theme),
                ),
              ),

              const Spacer(flex: 2),

              // Loading indicator and status
              _buildLoadingSection(theme),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  /// Build logo section with app branding
  Widget _buildLogoSection(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo container with mood emoji
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/ChatGPT_Image_Jan_31__2026__12_38_02_PM-1769881107516.png',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // App name
        Text(
          'MoodTap',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 8),

        // Tagline
        Text(
          'Track your daily emotions',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// Build loading indicator section
  Widget _buildLoadingSection(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Loading indicator
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Status message
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _statusMessage,
            key: ValueKey<String>(_statusMessage),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

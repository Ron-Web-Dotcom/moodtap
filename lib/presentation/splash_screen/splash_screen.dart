import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modern splash screen with premium gradient design
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
  late Animation<Offset> _slideAnimation;

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

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCorruptedData = await _checkDataIntegrity(prefs);
      if (hasCorruptedData) {
        await _handleCorruptedData(prefs);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 2200));
      if (mounted) Navigator.pushReplacementNamed(context, '/home-screen');
    } catch (e) {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 1000));
        Navigator.pushReplacementNamed(context, '/home-screen');
      }
    }
  }

  Future<bool> _checkDataIntegrity(SharedPreferences prefs) async {
    try {
      final moodHistory = prefs.getString('moodHistory');
      if (moodHistory != null && moodHistory.isNotEmpty) {
        if (!moodHistory.startsWith('[') && !moodHistory.startsWith('{'))
          return true;
      }
      return false;
    } catch (e) {
      return true;
    }
  }

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
    if (shouldReset == true) await prefs.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/home-screen');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF1565C0), Color(0xFF0D47A1)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative circles
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.3,
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        children: [
                          // App icon container
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('😊', style: TextStyle(fontSize: 52)),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // App name
                          Text(
                            'MoodTap',
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Track your emotional journey',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.75),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Bottom section
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          // Mood emoji row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: ['😢', '😕', '😐', '🙂', '😄'].map((
                              emoji,
                            ) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 40),

                          // Loading indicator
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading your moods...',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

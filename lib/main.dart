import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import './services/notification_service.dart';
import './services/supabase_service.dart';
import './widgets/custom_error_widget.dart';
import 'core/app_export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Sentry for crash reporting
  await SentryFlutter.init((options) {
    options.dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
    options.tracesSampleRate = 1.0;
    options.environment = const String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'production',
    );
    // Battery optimization: Reduce sample rate in production
    options.enableAutoSessionTracking = true;
    options.beforeSend = (event, hint) {
      // Filter out sensitive data
      if (event.user != null) {
        event = event.copyWith(
          user: event.user?.copyWith(
            email: null,
            username: null,
            ipAddress: null,
          ),
        );
      }
      return event;
    };
  }, appRunner: () => _initializeApp());
}

Future<void> _initializeApp() async {
  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e, stackTrace) {
    debugPrint('Supabase initialization failed: $e');
    await Sentry.captureException(
      e,
      stackTrace: stackTrace,
      hint: Hint.withMap({'context': 'Supabase initialization'}),
    );
  }

  // Migrate existing local data to Supabase (one-time operation)
  await _migrateLocalMoodsToSupabase();

  // Initialize notification service
  await NotificationService().initialize();

  bool _hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Report to Sentry
    Sentry.captureException(
      details.exception,
      stackTrace: details.stack,
      hint: Hint.withMap({'context': 'ErrorWidget'}),
    );

    if (!_hasShownError) {
      _hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        _hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    runApp(MyApp());
  });
}

/// Migrate existing SharedPreferences mood data to Supabase
Future<void> _migrateLocalMoodsToSupabase() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final migrationCompleted = prefs.getBool('migration_completed') ?? false;

    // Skip if migration already done
    if (migrationCompleted) return;

    final moodsJson = prefs.getString('mood_history');
    if (moodsJson == null || moodsJson.isEmpty) {
      // No local data to migrate, mark as completed
      await prefs.setBool('migration_completed', true);
      return;
    }

    // Parse local mood data
    final List<dynamic> moodsList = json.decode(moodsJson);
    final localMoods = moodsList
        .where((item) {
          if (item is! Map) return false;
          if (!item.containsKey('date') || !item.containsKey('mood'))
            return false;
          final moodValue = item['mood'];
          if (moodValue is! num) return false;
          final mood = moodValue.toInt();
          return mood >= 1 && mood <= 5;
        })
        .map(
          (item) => {
            'date': item['date'] as String,
            'mood': (item['mood'] as num).toInt(),
          },
        )
        .toList();

    if (localMoods.isNotEmpty) {
      // Migrate to Supabase
      await SupabaseService.instance.migrateLocalDataToSupabase(localMoods);
      debugPrint(
        'Successfully migrated ${localMoods.length} moods to Supabase',
      );
    }

    // Mark migration as completed
    await prefs.setBool('migration_completed', true);
  } catch (e, stackTrace) {
    debugPrint('Migration failed: $e');
    await Sentry.captureException(
      e,
      stackTrace: stackTrace,
      hint: Hint.withMap({'context': 'Data migration'}),
    );
    // Don't block app startup on migration failure
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.light;
  final GlobalKey<NavigatorState> myAppKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThemePreference();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Battery optimization: Clear cache when app goes to background
    if (state == AppLifecycleState.paused) {
      // App is in background, reduce memory usage
      SupabaseService.instance.clearCache();
    } else if (state == AppLifecycleState.resumed) {
      // App is back in foreground
      _loadThemePreference();
    }
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    if (mounted) {
      setState(() {
        _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      });
    }
  }

  /// Public method to update theme mode without restart
  void updateThemeMode(bool isDarkMode) {
    if (mounted) {
      setState(() {
        _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          key: myAppKey,
          title: 'moodtap',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          // 🚨 CRITICAL: Text scaling disabled for visual edit support
          // This is intentional and required for the platform
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          navigatorObservers: [SentryNavigatorObserver()],
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
        );
      },
    );
  }
}
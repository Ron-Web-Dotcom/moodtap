import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:sentry_flutter/sentry_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  String? _deviceUserId;

  // Cache for mood data to reduce API calls
  List<Map<String, dynamic>>? _cachedMoods;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  // Initialize Supabase - call this in main()
  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be defined using --dart-define.',
      );
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // Get Supabase client
  SupabaseClient get client => Supabase.instance.client;

  // Get device-based user ID (creates one if doesn't exist)
  Future<String> getAnonymousUserId() async {
    if (_deviceUserId != null) return _deviceUserId!;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedUserId = prefs.getString('device_user_id');

      if (storedUserId == null || storedUserId.isEmpty) {
        // Generate new UUID for this device
        storedUserId = _generateUuid();
        await prefs.setString('device_user_id', storedUserId);
      }

      _deviceUserId = storedUserId;
      return storedUserId;
    } catch (e) {
      throw Exception('Failed to get device user ID: $e');
    }
  }

  // Generate UUID v4 with cryptographically secure random
  String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    // Set version to 4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant to RFC 4122
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    return [
          bytes.sublist(0, 4),
          bytes.sublist(4, 6),
          bytes.sublist(6, 8),
          bytes.sublist(8, 10),
          bytes.sublist(10, 16),
        ]
        .map(
          (part) => part.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        )
        .join('-');
  }

  // Save or update mood with retry mechanism
  Future<void> saveMood({
    required String date,
    required int moodValue,
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < maxRetries) {
      try {
        final userId = await getAnonymousUserId();

        // Upsert: insert or update if exists
        await client.from('moods').upsert({
          'user_id': userId,
          'mood_date': date,
          'mood_value': moodValue,
        }, onConflict: 'user_id,mood_date');

        // Clear cache after successful save
        _cachedMoods = null;
        _cacheTimestamp = null;

        return; // Success
      } catch (e) {
        lastException = Exception('Failed to save mood: $e');
        attempt++;

        if (attempt < maxRetries) {
          // Exponential backoff: 1s, 2s, 4s
          await Future.delayed(Duration(seconds: pow(2, attempt - 1).toInt()));
        } else {
          // Report to Sentry after all retries failed
          await Sentry.captureException(
            lastException,
            hint: Hint.withMap({
              'context': 'saveMood',
              'date': date,
              'moodValue': moodValue,
              'attempts': attempt,
            }),
          );
        }
      }
    }

    throw lastException!;
  }

  // Load all moods with caching
  Future<List<Map<String, dynamic>>> loadMoods({
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _cachedMoods != null && _cacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cacheTimestamp!);
      if (cacheAge < _cacheDuration) {
        return _cachedMoods!;
      }
    }

    try {
      final userId = await getAnonymousUserId();

      final data = await client
          .from('moods')
          .select('mood_date, mood_value')
          .eq('user_id', userId)
          .order('mood_date', ascending: false);

      // Convert to format expected by app: {date: 'yyyy-MM-dd', mood: int}
      final moods = (data as List)
          .map(
            (row) => {
              'date': row['mood_date'] as String,
              'mood': row['mood_value'] as int,
            },
          )
          .toList();

      // Update cache
      _cachedMoods = moods;
      _cacheTimestamp = DateTime.now();

      return moods;
    } catch (e) {
      await Sentry.captureException(
        e,
        hint: Hint.withMap({'context': 'loadMoods'}),
      );
      throw Exception('Failed to load moods: $e');
    }
  }

  // Delete all moods for current user
  Future<void> deleteAllMoods() async {
    try {
      final userId = await getAnonymousUserId();

      await client.from('moods').delete().eq('user_id', userId);

      // Clear cache
      _cachedMoods = null;
      _cacheTimestamp = null;
    } catch (e) {
      await Sentry.captureException(
        e,
        hint: Hint.withMap({'context': 'deleteAllMoods'}),
      );
      throw Exception('Failed to delete moods: $e');
    }
  }

  // Get mood for specific date
  Future<int?> getMoodForDate(String date) async {
    try {
      final userId = await getAnonymousUserId();

      final data = await client
          .from('moods')
          .select('mood_value')
          .eq('user_id', userId)
          .eq('mood_date', date)
          .maybeSingle();

      return data?['mood_value'] as int?;
    } catch (e) {
      return null;
    }
  }

  // Get all moods (alias for loadMoods for backward compatibility)
  Future<List<Map<String, dynamic>>> getAllMoods() async {
    return loadMoods();
  }

  // Clear cache manually
  void clearCache() {
    _cachedMoods = null;
    _cacheTimestamp = null;
  }

  // Migrate local SharedPreferences data to Supabase (one-time operation)
  Future<void> migrateLocalDataToSupabase(
    List<Map<String, dynamic>> localMoods,
  ) async {
    if (localMoods.isEmpty) return;

    try {
      final userId = await getAnonymousUserId();

      // Batch insert all local moods to Supabase
      final moodsToInsert = localMoods
          .map(
            (mood) => {
              'user_id': userId,
              'mood_date': mood['date'] as String,
              'mood_value': mood['mood'] as int,
            },
          )
          .toList();

      // Use upsert to avoid duplicates
      await client
          .from('moods')
          .upsert(moodsToInsert, onConflict: 'user_id,mood_date');

      // Clear cache to force reload
      _cachedMoods = null;
      _cacheTimestamp = null;
    } catch (e) {
      await Sentry.captureException(
        e,
        hint: Hint.withMap({
          'context': 'migrateLocalDataToSupabase',
          'moodCount': localMoods.length,
        }),
      );
      throw Exception('Failed to migrate local data: $e');
    }
  }
}

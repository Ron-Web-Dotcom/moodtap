import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Generate UUID v4
  String _generateUuid() {
    final random = DateTime.now().microsecondsSinceEpoch;
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
      RegExp(r'[xy]'),
      (match) {
        final r = (random + (random * 16).toInt()) % 16;
        final v = match.group(0) == 'x' ? r : (r & 0x3 | 0x8);
        return v.toRadixString(16);
      },
    );
  }

  // Save or update mood for a specific date
  Future<void> saveMood({required String date, required int moodValue}) async {
    try {
      final userId = await getAnonymousUserId();

      // Upsert: insert or update if exists
      await client.from('moods').upsert({
        'user_id': userId,
        'mood_date': date,
        'mood_value': moodValue,
      }, onConflict: 'user_id,mood_date');
    } catch (e) {
      throw Exception('Failed to save mood: $e');
    }
  }

  // Load all moods for current user
  Future<List<Map<String, dynamic>>> loadMoods() async {
    try {
      final userId = await getAnonymousUserId();

      final data = await client
          .from('moods')
          .select('mood_date, mood_value')
          .eq('user_id', userId)
          .order('mood_date', ascending: false);

      // Convert to format expected by app: {date: 'yyyy-MM-dd', mood: int}
      return (data as List)
          .map(
            (row) => {
              'date': row['mood_date'] as String,
              'mood': row['mood_value'] as int,
            },
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load moods: $e');
    }
  }

  // Delete all moods for current user
  Future<void> deleteAllMoods() async {
    try {
      final userId = await getAnonymousUserId();

      await client.from('moods').delete().eq('user_id', userId);
    } catch (e) {
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
    } catch (e) {
      throw Exception('Failed to migrate local data: $e');
    }
  }
}

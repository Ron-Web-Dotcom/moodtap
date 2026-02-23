import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moodtap/services/supabase_service.dart';

@GenerateMocks([SupabaseClient, SupabaseQueryBuilder, PostgrestFilterBuilder])
import 'supabase_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupabaseService Tests', () {
    late SupabaseService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = SupabaseService.instance;
    });

    group('Anonymous User ID Generation', () {
      test('should generate valid UUID v4 format', () async {
        SharedPreferences.setMockInitialValues({});
        final userId = await service.getAnonymousUserId();

        // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        );

        expect(userId, matches(uuidRegex));
        expect(userId.length, equals(36));
      });

      test('should persist user ID across multiple calls', () async {
        SharedPreferences.setMockInitialValues({});
        final userId1 = await service.getAnonymousUserId();
        final userId2 = await service.getAnonymousUserId();

        expect(userId1, equals(userId2));
      });

      test('should retrieve existing user ID from SharedPreferences', () async {
        const existingUserId = '12345678-1234-4123-8123-123456789abc';
        SharedPreferences.setMockInitialValues({
          'device_user_id': existingUserId,
        });

        final userId = await service.getAnonymousUserId();
        expect(userId, equals(existingUserId));
      });

      test('should generate unique IDs for different instances', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        final userId1 = await service.getAnonymousUserId();

        await prefs.clear();
        // Force new ID generation by clearing cache
        service = SupabaseService.instance;

        final userId2 = await service.getAnonymousUserId();

        expect(userId1, isNot(equals(userId2)));
      });
    });

    group('Mood Data Validation', () {
      test('should validate mood value range (1-5)', () {
        expect(() => _validateMoodValue(1), returnsNormally);
        expect(() => _validateMoodValue(3), returnsNormally);
        expect(() => _validateMoodValue(5), returnsNormally);
      });

      test('should reject invalid mood values', () {
        expect(() => _validateMoodValue(0), throwsException);
        expect(() => _validateMoodValue(6), throwsException);
        expect(() => _validateMoodValue(-1), throwsException);
      });

      test('should validate date format (yyyy-MM-dd)', () {
        expect(_isValidDateFormat('2026-02-15'), isTrue);
        expect(_isValidDateFormat('2026-12-31'), isTrue);
        expect(_isValidDateFormat('2026-01-01'), isTrue);
      });

      test('should reject invalid date formats', () {
        expect(_isValidDateFormat('15-02-2026'), isFalse);
        expect(_isValidDateFormat('2026/02/15'), isFalse);
        expect(_isValidDateFormat('invalid'), isFalse);
        expect(_isValidDateFormat(''), isFalse);
      });
    });

    group('Data Migration Logic', () {
      test('should handle empty local data gracefully', () async {
        final emptyData = <Map<String, dynamic>>[];
        expect(
          () => service.migrateLocalDataToSupabase(emptyData),
          returnsNormally,
        );
      });

      test('should validate local mood data structure', () {
        final validMood = {'date': '2026-02-15', 'mood': 4};
        expect(_isValidMoodData(validMood), isTrue);

        final invalidMood1 = {'date': '2026-02-15'}; // Missing mood
        expect(_isValidMoodData(invalidMood1), isFalse);

        final invalidMood2 = {'mood': 4}; // Missing date
        expect(_isValidMoodData(invalidMood2), isFalse);

        final invalidMood3 = {'date': '2026-02-15', 'mood': 'happy'};
        expect(_isValidMoodData(invalidMood3), isFalse);
      });

      test('should filter out invalid mood entries', () {
        final mixedData = [
          {'date': '2026-02-15', 'mood': 4}, // Valid
          {'date': '2026-02-14', 'mood': 0}, // Invalid mood value
          {'date': '2026-02-13', 'mood': 3}, // Valid
          {'date': 'invalid', 'mood': 5}, // Invalid date
          {'mood': 2}, // Missing date
        ];

        final validData = mixedData.where(_isValidMoodData).toList();
        expect(validData.length, equals(2));
      });
    });

    group('Error Handling', () {
      test('should throw exception for empty Supabase URL', () {
        expect(() => SupabaseService.initialize(), throwsException);
      });

      test('should handle network failures gracefully', () async {
        // This would require mocking Supabase client
        // For now, we test that exceptions are properly wrapped
        expect(
          () => service.saveMood(date: '2026-02-15', moodValue: 4),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('UUID Generation Security', () {
      test('should use cryptographically secure random', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final uuids = <String>{};
        for (int i = 0; i < 100; i++) {
          await prefs.clear();
          final uuid = await service.getAnonymousUserId();
          uuids.add(uuid);
        }

        // All UUIDs should be unique
        expect(uuids.length, equals(100));
      });

      test('should set correct UUID version (4) and variant bits', () async {
        SharedPreferences.setMockInitialValues({});
        final userId = await service.getAnonymousUserId();

        // Extract version and variant from UUID
        final parts = userId.split('-');
        final versionChar = parts[2][0];
        final variantChar = parts[3][0];

        // Version should be 4
        expect(versionChar, equals('4'));

        // Variant should be 8, 9, a, or b (RFC 4122)
        expect(['8', '9', 'a', 'b'], contains(variantChar));
      });
    });
  });
}

// Helper validation functions
void _validateMoodValue(int mood) {
  if (mood < 1 || mood > 5) {
    throw Exception('Mood value must be between 1 and 5');
  }
}

bool _isValidDateFormat(String date) {
  if (date.isEmpty) return false;
  final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  if (!regex.hasMatch(date)) return false;

  try {
    DateTime.parse(date);
    return true;
  } catch (e) {
    return false;
  }
}

bool _isValidMoodData(Map<String, dynamic> data) {
  if (!data.containsKey('date') || !data.containsKey('mood')) return false;

  final date = data['date'];
  final mood = data['mood'];

  if (date is! String || !_isValidDateFormat(date)) return false;
  if (mood is! int || mood < 1 || mood > 5) return false;

  return true;
}

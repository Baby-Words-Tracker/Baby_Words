import 'package:baby_words_tracker/data/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile scheduled notification settings', () {
    test('defaults to an empty scheduled notification list', () {
      final profile = UserProfile(id: 'parent-1', role: UserRole.parent);

      expect(profile.scheduledNotificationMinutes, isEmpty);
      expect(profile.toMap()['scheduledNotificationMinutes'], isEmpty);
    });

    test('handles null scheduled notification list safely', () {
      final profile = UserProfile(
        id: 'parent-1',
        role: UserRole.parent,
        scheduledNotificationMinutes: null,
      );

      expect(profile.scheduledNotificationMinutes, isEmpty);
      expect(profile.toMap()['scheduledNotificationMinutes'], isEmpty);
    });

    test('parses, de-duplicates, sorts, and validates stored reminder times',
        () {
      final profile = UserProfile.fromMap({
        'id': 'parent-1',
        'role': 'parent',
        'scheduledNotificationMinutes': [
          20 * 60 + 15,
          -1,
          8 * 60,
          8 * 60,
          24 * 60,
          12.0 * 60,
          'not-a-time',
        ],
      });

      expect(profile.scheduledNotificationMinutes,
          [8 * 60, 12 * 60, 20 * 60 + 15]);
    });

    test('copyWith can update scheduled notification times', () {
      final profile = UserProfile(
        id: 'parent-1',
        role: UserRole.parent,
        scheduledNotificationMinutes: [8 * 60],
      );

      final updated = profile.copyWith(
        scheduledNotificationMinutes: [9 * 60 + 30, 18 * 60],
      );

      expect(updated.scheduledNotificationMinutes, [9 * 60 + 30, 18 * 60]);
      expect(profile.scheduledNotificationMinutes, [8 * 60]);
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android notification manifest configuration', () {
    late String manifest;

    setUpAll(() {
      manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    });

    test('declares notification permissions used by scheduled reminders', () {
      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('android.permission.SCHEDULE_EXACT_ALARM'));
      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    });

    test('declares flutter_local_notifications scheduled receivers', () {
      expect(
        manifest,
        contains(
            'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver'),
      );
      expect(
        manifest,
        contains(
            'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver'),
      );
      expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
      expect(manifest, contains('android.intent.action.MY_PACKAGE_REPLACED'));
    });
  });
}

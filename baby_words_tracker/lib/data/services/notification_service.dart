import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/data/services/user_profile_service.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const int _scheduledNotificationBaseId = 41000;
  static const AndroidNotificationDetails _androidScheduledDetails =
      AndroidNotificationDetails(
    'daily_wordbuds_reminders',
    'Daily WordBuds reminders',
    channelDescription: 'Daily reminders to log your child\'s words.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );
  static const DarwinNotificationDetails _iosScheduledDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  // Dependencies to save token
  final UserProfileService? _userProfileService;
  final AuthenticationService? _authService;

  NotificationService({
    UserProfileService? userProfileService,
    AuthenticationService? authService,
  })  : _userProfileService = userProfileService,
        _authService = authService {
    _authService?.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authService?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (_authService?.userId != null && _fcmToken != null) {
      _saveTokenToProfile(_fcmToken!);
    }
  }

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _authorized = false;
  bool get authorized => _authorized;

  bool _localNotificationsInitialized = false;

  Future<void> initialize() async {
    await _initializeLocalNotifications();

    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    _authorized =
        settings.authorizationStatus == AuthorizationStatus.authorized;
    debugPrint(
        'User granted notification permission: ${settings.authorizationStatus}');

    if (_authorized) {
      // 2. Set background handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // 3. Get Token
      await _getToken();

      // 4. Setup Listeners
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
              'Message also contained a notification: ${message.notification}');
          // In the future, you could show a local notification here
        }
      });

      // Handle token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveTokenToProfile(newToken);
      });
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) return;

    tz.initializeTimeZones();
    try {
      final localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone));
    } catch (e) {
      debugPrint('Unable to set local timezone for notifications: $e');
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(initializationSettings);
    await _requestLocalNotificationPermissions();
    _localNotificationsInitialized = true;
  }

  Future<void> _requestLocalNotificationPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleDailyNotifications(
      List<int> minutesSinceMidnight) async {
    await _initializeLocalNotifications();
    await cancelScheduledNotifications();

    final uniqueMinutes = minutesSinceMidnight
        .where((minutes) => minutes >= 0 && minutes < 24 * 60)
        .toSet()
        .toList()
      ..sort();

    for (var i = 0; i < uniqueMinutes.length; i++) {
      final minutes = uniqueMinutes[i];
      await _scheduleDailyNotification(
        id: _scheduledNotificationBaseId + i,
        minutesSinceMidnight: minutes,
      );
    }
  }

  Future<void> cancelScheduledNotifications() async {
    for (var i = 0; i < 64; i++) {
      await _localNotifications.cancel(_scheduledNotificationBaseId + i);
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required int minutesSinceMidnight,
  }) async {
    final hour = minutesSinceMidnight ~/ 60;
    final minute = minutesSinceMidnight % 60;
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    try {
      await _localNotifications.zonedSchedule(
        id,
        'WordBuds reminder',
        'Take a moment to log new words today.',
        scheduledDate,
        const NotificationDetails(
          android: _androidScheduledDetails,
          iOS: _iosScheduledDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.exact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Exact notification scheduling failed, falling back: $e');
      await _localNotifications.zonedSchedule(
        id,
        'WordBuds reminder',
        'Take a moment to log new words today.',
        scheduledDate,
        const NotificationDetails(
          android: _androidScheduledDetails,
          iOS: _iosScheduledDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> _getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _fcmToken = token;
        debugPrint("FCM Token: $token");
        await _saveTokenToProfile(token);
      }
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }
  }

  Future<void> _saveTokenToProfile(String token) async {
    final userProfileService = _userProfileService;
    final authService = _authService;
    if (userProfileService != null && authService != null) {
      final userId = authService.userId;
      if (userId != null) {
        debugPrint("Saving FCM Token for user $userId");
        try {
          await userProfileService.updateUserProfile(userId, {
            'fcmToken': token,
            'lastTokenUpdate': DateTime.now(),
          });
        } catch (e) {
          debugPrint("Failed to save token to profile: $e");
        }
      }
    }
  }
}

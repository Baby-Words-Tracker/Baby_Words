import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/data/models/user_profile.dart';
import 'package:baby_words_tracker/data/services/user_profile_service.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Dependencies to save token
  final UserProfileService? _userProfileService;
  final AuthenticationService? _authService;

  NotificationService({
    UserProfileService? userProfileService,
    AuthenticationService? authService,
  }) : _userProfileService = userProfileService,
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

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    _authorized = settings.authorizationStatus == AuthorizationStatus.authorized;
    debugPrint('User granted notification permission: ${settings.authorizationStatus}');
    
    if (_authorized) {
      // 2. Set background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Get Token
      await _getToken();

      // 4. Setup Listeners
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
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
    if (_userProfileService != null && _authService != null) {
      final userId = _authService!.userId;
      if (userId != null) {
        debugPrint("Saving FCM Token for user $userId");
        try {
          // This assumes the UserProfileService has an update method
          // and the UserProfile model will eventually support 'fcmTokens'
          // For now, we'll try to update it as a generic field or skip if not ready
           await _userProfileService!.updateUserProfile(userId, {
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

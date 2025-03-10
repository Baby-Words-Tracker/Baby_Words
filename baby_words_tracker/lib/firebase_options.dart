// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBNam4f6Ak87lrLvof0AEA8ob0tRpna-G4',
    appId: '1:37552098276:web:e7918a8c8351283560d5f1',
    messagingSenderId: '37552098276',
    projectId: 'baby-word-tracker',
    authDomain: 'baby-word-tracker.firebaseapp.com',
    storageBucket: 'baby-word-tracker.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDw0xn1tqT9cP2Po5WFPEgkQ8Xf7To4BO0',
    appId: '1:37552098276:android:e325a32d1990f42f60d5f1',
    messagingSenderId: '37552098276',
    projectId: 'baby-word-tracker',
    storageBucket: 'baby-word-tracker.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDOG5i6PyQR6xnc0lccZ_ikDXGusZsnxUs',
    appId: '1:37552098276:ios:707cf7ede5b178d160d5f1',
    messagingSenderId: '37552098276',
    projectId: 'baby-word-tracker',
    storageBucket: 'baby-word-tracker.firebasestorage.app',
    androidClientId: '37552098276-62gnq8ula4275n94hoev1hdh6dd33vuc.apps.googleusercontent.com',
    iosClientId: '37552098276-0okgdbhghlc9di6svkvf7losu9esrp29.apps.googleusercontent.com',
    iosBundleId: 'com.example.babyWordsTracker',
  );

}
# Firebase Auth & 2FA Setup Guide

**Date:** October 8, 2025  
**Purpose:** Complete setup for Firebase Authentication with Phone 2FA

---

## 🔐 What's Already Configured

✅ **Firebase Auth Integration**
- Email/Password authentication
- Google Sign-In
- Firebase UI for auth screens
- Custom claims for user roles

✅ **Code Implementation**
- Phone verification flow (`PhoneVerificationPage`)
- Firebase Phone Auth integration
- UserProfile 2FA tracking
- Automatic credential linking

---

## 📱 Phone Auth (2FA) Requirements

### 1. **Enable Phone Authentication in Firebase Console**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Authentication** → **Sign-in method**
4. Enable **Phone** provider
5. Click **Save**

### 2. **Android Setup (SHA Keys Required)**

Firebase Phone Auth requires SHA-1 and SHA-256 certificates for Android.

#### **Get Your SHA Keys**

**For Debug Build:**
```bash
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker/android

# Get SHA-1 and SHA-256
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**For Release Build (if you have a keystore):**
```bash
# If using custom keystore (check android/app/key.properties)
keytool -list -v -keystore path/to/your/keystore.jks -alias your-alias
```

#### **Add SHA Keys to Firebase**

1. Go to Firebase Console → Project Settings
2. Scroll to **Your apps** section
3. Find your Android app (`com.example.baby_words_tracker`)
4. Click **Add fingerprint**
5. Paste your **SHA-1** key
6. Click **Add fingerprint** again
7. Paste your **SHA-256** key
8. Click **Save**

#### **Download Updated google-services.json**

1. In Firebase Console, go to Project Settings
2. Find your Android app
3. Click **Download google-services.json**
4. Replace the file at:
   ```
   /Users/chase/Repositories/Baby_Words/baby_words_tracker/android/app/google-services.json
   ```

### 3. **iOS Setup (APNs Required)**

Firebase Phone Auth on iOS requires APNs (Apple Push Notification Service).

#### **Generate APNs Certificates**

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Create an **APNs Key** or **APNs Certificate**
4. Download the key/certificate

#### **Upload to Firebase**

1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Under **Apple app configuration**
3. Upload your APNs Key or Certificate
4. Enter Team ID and Key ID

#### **Update iOS Capabilities**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **Push Notifications**

### 4. **Emulator Setup (Optional)**

If you want to use Firebase Emulators for testing:

#### **Install Emulator Suite**
```bash
cd /Users/chase/Repositories/Baby_Words/firebase-project
npm install -g firebase-tools
firebase init emulators
```

#### **Enable Auth Emulator**
Select:
- ✅ Authentication Emulator
- ✅ Firestore Emulator (if needed)

#### **Configure in Flutter**

Update your main.dart to connect to emulators in debug mode:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Connect to emulators in debug mode
  if (kDebugMode) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  
  runApp(MyApp());
}
```

**Note:** Phone Auth emulator has limitations - real SMS won't be sent. Use test phone numbers instead.

#### **Add Test Phone Numbers (Emulator)**

1. Firebase Console → Authentication → Sign-in method
2. Scroll to **Phone** section
3. Click **Add test phone number**
4. Add: `+1 650-555-1234` with code `123456`
5. Use these in development

---

## 🔧 Configuration Files

### **Android Configuration**

**File:** `android/app/build.gradle`

Already configured:
```gradle
plugins {
    id "com.android.application"
    id 'com.google.gms.google-services'  // ✅ Firebase plugin
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    defaultConfig {
        applicationId = "com.example.baby_words_tracker"
        minSdkVersion = flutter.minSdkVersion  // Must be 21+ for Phone Auth
        targetSdk = flutter.targetSdkVersion
    }
}
```

**Minimum SDK for Phone Auth:** Android 21 (Lollipop) or higher

### **Firebase Dependencies**

Check `pubspec.yaml` includes:
```yaml
dependencies:
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
```

---

## 🧪 Testing Phone Auth

### **Test Flow on Android**

1. **Build and run:**
   ```bash
   cd /Users/chase/Repositories/Baby_Words/baby_words_tracker
   flutter run
   ```

2. **Register new user:**
   - Email: test@example.com
   - Password: testpass123

3. **Verify email** (check console for verification link)

4. **Phone verification screen:**
   - Enter phone: `+1 234 567 8900`
   - You should receive real SMS

5. **Enter SMS code**

6. **Verify success:**
   - Check debug logs for "2FA enabled"
   - Check Firestore UserProfile.twoFactorEnabled = true

### **Test with Emulator Phone Numbers**

If using Firebase emulator:

1. Use test number: `+1 650-555-1234`
2. Use test code: `123456` (or whatever you configured)
3. Should work without real SMS

### **Common Issues**

#### ❌ "SMS quota exceeded"
**Cause:** Firebase free tier limit reached  
**Fix:** 
- Use test phone numbers
- Upgrade to Blaze plan
- Wait 24 hours for quota reset

#### ❌ "Invalid format" error
**Cause:** Phone number format incorrect  
**Fix:** Always include country code: `+1` for US

#### ❌ "reCAPTCHA verification failed"
**Cause:** Missing SHA keys on Android  
**Fix:** 
1. Get SHA-1 and SHA-256 keys
2. Add to Firebase Console
3. Download new google-services.json
4. Rebuild app

#### ❌ "Network error" on iOS
**Cause:** APNs not configured  
**Fix:**
1. Add APNs certificate/key to Firebase
2. Enable Push Notifications in Xcode
3. Test on physical device (not simulator)

---

## 🚀 Production Deployment Checklist

### **Before Going Live**

- [ ] Add production SHA-1 and SHA-256 to Firebase
- [ ] Configure APNs for iOS production
- [ ] Set up Phone Auth billing (Blaze plan recommended)
- [ ] Test phone verification on real devices
- [ ] Monitor SMS quota usage
- [ ] Set up phone number abuse detection
- [ ] Add SMS region restrictions if needed

### **Firebase Console Settings**

**Authentication → Settings:**
- ✅ Enable **Email Enumeration Protection**
- ✅ Set **Password policy** (if needed)
- ✅ Configure **Authorized domains**
- ✅ Set up **SMS quota alerts**

**Phone Provider Settings:**
- Set daily SMS limit
- Enable reCAPTCHA verification
- Configure test phone numbers for QA

---

## 📊 Current Implementation

### **Phone Verification Flow**

```dart
// 1. User enters phone number
_phoneController.text = "+1 234 567 8900"

// 2. Send verification code
await FirebaseAuth.instance.verifyPhoneNumber(
  phoneNumber: phoneNumber,
  verificationCompleted: (credential) {
    // Auto-verification (Android only)
    await user.linkWithCredential(credential);
    await userModelService.enable2FA(phoneNumber: phoneNumber);
  },
  codeSent: (verificationId, resendToken) {
    // Show code input screen
  },
  verificationFailed: (error) {
    // Show error
  },
);

// 3. User enters code
final credential = PhoneAuthProvider.credential(
  verificationId: verificationId,
  smsCode: code,
);

// 4. Link to account
await user.linkWithCredential(credential);

// 5. Save to UserProfile
await userModelService.enable2FA(phoneNumber: phoneNumber);
```

### **UserProfile Fields**

```dart
class UserProfile {
  final bool twoFactorEnabled;      // Track 2FA status
  final DateTime? twoFactorEnabledAt;  // When enabled
  final String? phoneNumber;         // Verified phone
}
```

---

## 🔍 Debugging

### **Enable Firebase Debug Logging**

**Android:**
```bash
adb shell setprop log.tag.FirebaseAuth DEBUG
adb logcat | grep FirebaseAuth
```

**iOS:**
```swift
// In AppDelegate.swift
FirebaseConfiguration.shared.setLoggerLevel(.debug)
```

### **Check Phone Auth Status**

```dart
final user = FirebaseAuth.instance.currentUser;

// Check if phone is linked
final phoneProvider = user?.providerData.firstWhere(
  (info) => info.providerId == 'phone',
  orElse: () => null,
);

if (phoneProvider != null) {
  print('Phone linked: ${phoneProvider.phoneNumber}');
}
```

### **Verify UserProfile**

```dart
final profile = await userProfileService.getUserProfile(userId);
print('2FA Enabled: ${profile.twoFactorEnabled}');
print('Phone: ${profile.phoneNumber}');
print('Enabled At: ${profile.twoFactorEnabledAt}');
```

---

## 📝 Quick Start Commands

### **Get SHA Keys (Android)**
```bash
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker/android
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA
```

### **Run with Emulators**
```bash
# Terminal 1: Start emulators
cd /Users/chase/Repositories/Baby_Words/firebase-project
firebase emulators:start

# Terminal 2: Run app
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker
flutter run
```

### **Test Phone Auth**
```bash
# Use test number (no real SMS)
Phone: +1 650-555-1234
Code: 123456
```

---

## 🎯 Next Steps

1. **Get SHA keys** and add to Firebase Console
2. **Download updated** google-services.json
3. **Test phone verification** on Android device
4. **Configure APNs** for iOS (if needed)
5. **Add test phone numbers** for development
6. **Monitor SMS quota** in Firebase Console

---

## 📞 Support Resources

- [Firebase Phone Auth Docs](https://firebase.google.com/docs/auth/flutter/phone-auth)
- [SHA Key Generation](https://developers.google.com/android/guides/client-auth)
- [APNs Setup Guide](https://firebase.google.com/docs/cloud-messaging/ios/certs)
- [Firebase Emulator](https://firebase.google.com/docs/emulator-suite)

---

**Need Help?** Check Firebase Console logs and debug output for detailed error messages.


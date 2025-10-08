# Phone Auth SHA Key Troubleshooting

**Error:** `Invalid app info in play_integrity_token`

This means Firebase doesn't recognize your app, even though you added SHA keys. Here's how to fix it:

---

## 🔧 Step-by-Step Fix

### 1. **Get the CORRECT SHA Keys** (Most Important!)

The issue is often using the wrong keystore. Run this command:

```bash
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker/android

# Debug keystore (what you're probably using now)
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

**Copy BOTH:**
- SHA-1: `XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX`
- SHA-256: `XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX`

### 2. **Verify Package Name**

Check your package name:

```bash
# Should be: com.example.baby_words_tracker
grep "applicationId" android/app/build.gradle
```

**Expected output:**
```
applicationId = "com.example.baby_words_tracker"
```

### 3. **Add SHA Keys to Firebase Console**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click ⚙️ (Settings) → **Project settings**
4. Scroll to **Your apps** section
5. Find **Android app** with package `com.example.baby_words_tracker`
6. Click **Add fingerprint**
7. Paste **SHA-1** → Save
8. Click **Add fingerprint** again
9. Paste **SHA-256** → Save

### 4. **Download NEW google-services.json**

**CRITICAL:** You MUST download a fresh file after adding SHA keys!

1. In Firebase Console, same screen as above
2. Click **Download google-services.json**
3. Replace the file:
   ```bash
   # Backup old one first
   cp android/app/google-services.json android/app/google-services.json.backup
   
   # Replace with new one (download to Downloads folder first)
   cp ~/Downloads/google-services.json android/app/google-services.json
   ```

### 5. **Clean Build (REQUIRED!)**

```bash
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker

# Clean everything
flutter clean
cd android
./gradlew clean
cd ..

# Rebuild from scratch
flutter pub get
flutter build apk --debug
```

### 6. **Reinstall App**

```bash
# Uninstall old app completely
adb uninstall com.example.baby_words_tracker

# Install fresh build
flutter run
```

---

## 🔍 Verify It's Fixed

After rebuilding, you should see in console:

```
✅ PhoneVerificationPage: Code sent to +1 XXX XXX XXXX
```

Instead of:
```
❌ Invalid app info in play_integrity_token
```

---

## 🚨 Common Mistakes

### ❌ **Wrong Keystore**

You might have a custom keystore. Check `android/app/key.properties`:

```bash
cat android/app/key.properties
```

If it exists, use THAT keystore instead:

```bash
keytool -list -v \
  -keystore /path/from/key.properties \
  -alias YOUR_ALIAS \
  -storepass YOUR_PASSWORD
```

### ❌ **Didn't Rebuild**

Adding SHA keys requires a FULL REBUILD:
- `flutter clean` ✅
- Rebuild app ✅
- Reinstall app ✅

Hot reload/restart is NOT enough!

### ❌ **Wrong Package Name**

Firebase must have EXACT package name:
- Firebase: `com.example.baby_words_tracker`
- Your app: Must match exactly

### ❌ **Old google-services.json**

The file is updated when you add SHA keys. You MUST download the new one!

---

## 📋 Quick Checklist

- [ ] Get SHA-1 from debug keystore
- [ ] Get SHA-256 from debug keystore
- [ ] Verify package name matches
- [ ] Add BOTH SHA keys to Firebase Console
- [ ] Download NEW google-services.json
- [ ] Replace android/app/google-services.json
- [ ] Run `flutter clean`
- [ ] Run `cd android && ./gradlew clean`
- [ ] Uninstall old app from device
- [ ] Rebuild: `flutter run`
- [ ] Test phone verification

---

## 🧪 Alternative: Use Test Phone Numbers

While debugging, use test numbers to skip real SMS:

1. **Firebase Console** → Authentication → Sign-in method
2. Scroll to **Phone** section
3. Click **Add test phone number**
4. Add:
   - Phone: `+1 650 555 1234`
   - Code: `123456`
5. In app, use this number - no SHA keys needed!

---

## 🛠️ Debug Commands

### Check Current SHA Keys
```bash
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android | grep SHA
```

### Check Package Name
```bash
grep "applicationId" /Users/chase/Repositories/Baby_Words/baby_words_tracker/android/app/build.gradle
```

### Check google-services.json Package
```bash
grep "package_name" /Users/chase/Repositories/Baby_Words/baby_words_tracker/android/app/google-services.json
```

All three should match!

---

## 💡 Pro Tips

**Use Emulator Firebase for Development:**

Set up Firebase emulators to avoid SHA issues entirely:

```bash
cd /Users/chase/Repositories/Baby_Words/firebase-project
firebase emulators:start
```

Then in your app, connect to emulator (see FIREBASE_AUTH_2FA_SETUP.md)

**Or Disable Phone Auth Temporarily:**

In `onboarding_flow_manager.dart`, comment out phone check:

```dart
// TEMP: Skip phone verification
// if (!userProfile.twoFactorEnabled) {
//   return OnboardingStep.phoneVerification;
// }
```

---

## 📞 Still Not Working?

1. **Double-check SHA keys match** - Run keytool command again
2. **Verify Firebase has your SHA keys** - Check Firebase Console
3. **Ensure google-services.json is fresh** - Download date should be TODAY
4. **Try different keystore** - Check if you have custom keystore
5. **Use test phone numbers** - Bypass SHA requirement

**Last Resort:**
- Delete app from Firebase Console
- Re-add app with correct settings
- Download new google-services.json
- Rebuild from scratch


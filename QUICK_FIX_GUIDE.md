# Quick Fix Guide - October 8, 2025

## ✅ Issue 1: Email Verification Fixed

**Problem:** Screen didn't advance after email verification until hot reload.

**Root Cause:** AuthGate was using `authStateChanges()` which only fires on sign-in/sign-out, NOT when user properties like email verification change.

**Solution Applied:** Changed to `userChanges()` stream which fires on ALL user property changes.

**Test It:**
1. Register with new email
2. Click verification link in email
3. Return to app
4. Screen should auto-advance within 3 seconds (no hot reload needed!)

---

## 🔧 Issue 2: Phone Auth SHA Key Error

**Error You're Seeing:**
```
Invalid app info in play_integrity_token
This app is not authorized to use Firebase Authentication
```

**This means:** Firebase doesn't recognize your app even though you added SHA keys.

### **Quick Fix Steps:**

#### 1. Get FRESH SHA Keys
```bash
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker/android

keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android
```

**Copy BOTH lines that start with:**
- `SHA1: XX:XX:XX:...`
- `SHA256: XX:XX:XX:...`

#### 2. Add to Firebase Console (Again)
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Project Settings → Your apps → Android app
3. Click "Add fingerprint"
4. Paste SHA-1 → Save
5. Click "Add fingerprint" again
6. Paste SHA-256 → Save

#### 3. Download NEW google-services.json
**⚠️ CRITICAL:** Download a fresh file AFTER adding SHA keys!

1. Same screen in Firebase Console
2. Click "Download google-services.json"
3. Replace file:
```bash
cp ~/Downloads/google-services.json \
   /Users/chase/Repositories/Baby_Words/baby_words_tracker/android/app/google-services.json
```

#### 4. Complete Clean Rebuild
```bash
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker

# Clean everything
flutter clean
cd android
./gradlew clean
cd ..

# Get dependencies
flutter pub get
```

#### 5. Uninstall Old App & Reinstall
```bash
# Uninstall completely
adb uninstall com.example.baby_words_tracker

# Reinstall fresh
flutter run
```

### **Alternative: Use Test Phone Numbers (No SHA Required!)**

While you fix SHA keys, use test numbers:

1. **Firebase Console** → Authentication → Sign-in method
2. Scroll to Phone section
3. Add test number:
   - Phone: `+1 650 555 1234`
   - Code: `123456`
4. Use this number in app - works without SHA keys!

---

## 🎯 What Changed in the Code

### AuthGate (new_auth_gate.dart)
```dart
// BEFORE (only detects sign-in/sign-out)
stream: FirebaseAuth.instance.authStateChanges()

// AFTER (detects email verification too!)
stream: FirebaseAuth.instance.userChanges()
```

### Email Verification (email_verification_page.dart)
- Auto-checks now happen **silently** (no screen flashing)
- Simpler reload logic (no complex token refresh)
- `userChanges()` stream automatically detects verification

---

## 📋 Testing Checklist

### Email Verification:
- [ ] Register with new test email
- [ ] Check email inbox (or spam)
- [ ] Click verification link
- [ ] Return to app
- [ ] **Screen should advance automatically** (no hot reload!)

### Phone Verification (after SHA fix):
- [ ] Complete SHA key steps above
- [ ] Uninstall and reinstall app
- [ ] Enter real phone number: `+1 XXX XXX XXXX`
- [ ] Receive real SMS
- [ ] Enter code
- [ ] Should advance to privacy policy

### Phone Verification (test numbers):
- [ ] Add test number in Firebase Console
- [ ] Enter: `+1 650 555 1234`
- [ ] Enter code: `123456`
- [ ] Should advance (no real SMS sent)

---

## 🐛 Common Mistakes

### ❌ "I added SHA keys but still getting error"
- Did you download NEW google-services.json? ✅
- Did you run `flutter clean`? ✅
- Did you uninstall old app? ✅
- Did you rebuild from scratch? ✅

**Hot reload is NOT enough! Must rebuild completely.**

### ❌ "Test phone numbers not working"
- Make sure Phone provider is enabled in Firebase Console
- Test numbers must be in format: `+1 650 555 1234`
- Test code is what YOU set (e.g., `123456`)

---

## 💡 Pro Tips

**Speed up testing:**
```dart
// Temporarily skip phone verification in onboarding_flow_manager.dart
// COMMENT OUT this check:
// if (!userProfile.twoFactorEnabled) {
//   return OnboardingStep.phoneVerification;
// }
```

**Use Gmail tags for unlimited test emails:**
- `yourname+test1@gmail.com`
- `yourname+test2@gmail.com`
- All go to same inbox!

---

## 📞 Next Steps

1. **Test email verification** (should work now!)
2. **Follow SHA fix steps** for phone auth
3. **Or use test phone numbers** to skip SHA setup temporarily

---

## 🔍 Verify It's Working

**Email verification working:**
```
✅ EmailVerificationPage: Email verified!
✅ AuthGate will now detect verification and advance
NewAuthGate: Onboarding step: Phone Verification  ← Should see this!
```

**Phone verification working:**
```
✅ PhoneVerificationPage: Code sent to +1 XXX XXX XXXX
```

**Phone verification still broken:**
```
❌ Invalid app info in play_integrity_token
```
→ Follow SHA key steps again, make sure you got NEW google-services.json!

---

**Questions?** Check **PHONE_AUTH_TROUBLESHOOTING.md** for detailed debugging steps.


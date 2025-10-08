# Onboarding Flow Refactor - Summary

**Date:** October 8, 2025  
**Status:** ✅ Complete

---

## ✅ What Was Done

### 1. **Moved Survey to Onboarding Folder**
- **Old:** `lib/pages/required_survey_page.dart`
- **New:** `lib/pages/onboarding/survey_page.dart`
- **Updated:** Consistent styling with other onboarding pages
- **Updated:** All imports in `new_auth_gate.dart` and `main.dart`

### 2. **Verified Firebase Auth Integration**

✅ **Email/Password Auth** - Already working  
✅ **Google Sign-In** - Already configured  
✅ **Phone Auth (2FA)** - Code implemented, needs setup  

### 3. **Created Setup Documentation**

📄 **FIREBASE_AUTH_2FA_SETUP.md** - Complete guide for:
- Getting SHA-1 and SHA-256 keys
- Configuring Firebase Console
- Testing phone verification
- iOS APNs setup
- Emulator configuration
- Troubleshooting

---

## 📁 Current Onboarding Structure

```
lib/pages/onboarding/
├── email_verification_page.dart    ✅ Step 1: Email verification
├── phone_verification_page.dart    ✅ Step 2: Phone/2FA
├── privacy_policy_page.dart        ✅ Step 3: Privacy policy
└── survey_page.dart                ✅ Step 4: Research survey
```

All managed by: `lib/auth/onboarding_flow_manager.dart`

---

## 🔐 Firebase Phone Auth Status

### **What's Implemented (Code)**
✅ Phone number input with validation  
✅ SMS code sending via Firebase  
✅ Code verification  
✅ Credential linking to user account  
✅ Phone number saved to UserProfile  
✅ 2FA status tracking  
✅ Skip option (temporary)  

### **What You Need to Configure (Firebase)**

#### **For Android Testing:**
1. **Get SHA keys:**
   ```bash
   cd /Users/chase/Repositories/Baby_Words/baby_words_tracker/android
   keytool -list -v -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android -keypass android
   ```

2. **Add to Firebase Console:**
   - Copy SHA-1 and SHA-256
   - Go to Firebase Console → Project Settings → Your Android App
   - Click "Add fingerprint"
   - Paste both keys

3. **Download new google-services.json:**
   - Download from Firebase Console
   - Replace: `android/app/google-services.json`

4. **Enable Phone Auth:**
   - Firebase Console → Authentication → Sign-in method
   - Enable "Phone" provider

#### **For iOS Testing:**
1. **Configure APNs:**
   - Upload APNs certificate/key to Firebase Console
   - Enable Push Notifications in Xcode

2. **Test on Physical Device:**
   - iOS Simulator doesn't support SMS
   - Must test on real iPhone

#### **For Development (Test Numbers):**
1. **Add test phone numbers:**
   - Firebase Console → Authentication → Sign-in method
   - Phone section → Add test number
   - Example: `+1 650-555-1234` with code `123456`

---

## 🧪 Testing Checklist

### **Local Development (Emulator)**

You mentioned you're using **local emulator with prod Firebase**. Here's the recommended approach:

**Option 1: Use Prod Firebase (Current)**
- ✅ Real authentication
- ✅ Real Firestore data
- ❌ Uses SMS quota
- ❌ Requires SHA keys
- **Best for:** Testing full flow with real SMS

**Option 2: Use Firebase Emulators**
- ✅ No SMS quota usage
- ✅ Test phone numbers work without real SMS
- ✅ No SHA keys needed
- ❌ Must set up emulator suite
- **Best for:** Development without SMS costs

### **Quick Start Commands**

**Test with Prod Firebase (Real SMS):**
```bash
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker

# Make sure SHA keys are added to Firebase Console first!
flutter run
```

**Test with Firebase Emulators (No SMS):**
```bash
# Terminal 1: Start emulators
cd /Users/chase/Repositories/Baby_Words/firebase-project
firebase emulators:start

# Terminal 2: Update main.dart to use emulators
# (See FIREBASE_AUTH_2FA_SETUP.md for code)

# Terminal 3: Run app
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker
flutter run
```

---

## 📋 Next Steps

### **Immediate (To Test Phone Auth):**

1. **Get your SHA keys** (5 min)
   ```bash
   cd android
   keytool -list -v -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android -keypass android | grep SHA
   ```

2. **Add to Firebase Console** (2 min)
   - Project Settings → Android App → Add fingerprints
   - Add both SHA-1 and SHA-256

3. **Download google-services.json** (1 min)
   - Replace existing file

4. **Enable Phone Auth provider** (1 min)
   - Authentication → Sign-in method → Enable Phone

5. **Test the flow** (5 min)
   ```bash
   flutter run
   # Register → Email verification → Phone verification
   ```

### **Optional (For Better Dev Experience):**

- [ ] Set up Firebase emulators for free testing
- [ ] Add test phone numbers to avoid SMS charges
- [ ] Configure APNs for iOS testing
- [ ] Set up CI/CD with emulators

### **Future (When Ready):**

- [ ] Replace survey placeholder with real survey
- [ ] Add onboarding progress indicator
- [ ] Add analytics tracking for onboarding steps
- [ ] Implement "Resume later" feature

---

## 🐛 Common Issues & Solutions

### **"SMS not received"**
**Check:**
- [ ] Phone provider enabled in Firebase Console
- [ ] SHA keys added for Android
- [ ] Phone number format: `+1 234 567 8900` (with country code)
- [ ] SMS quota not exceeded (check Firebase Console)

### **"reCAPTCHA failed"**
**Fix:**
- Add SHA-1 and SHA-256 to Firebase Console
- Download new google-services.json
- Rebuild app: `flutter clean && flutter run`

### **"Network error"**
**Check:**
- Internet connection
- Firebase services are up (check status.firebase.google.com)
- Firestore rules allow writes to UserProfile

---

## 📚 Documentation Files

1. **ONBOARDING_FLOW_GUIDE.md**
   - Complete onboarding architecture
   - How to add/remove/modify steps
   - User experience flows
   - Testing strategies

2. **FIREBASE_AUTH_2FA_SETUP.md** ⭐ **Start here!**
   - SHA key generation
   - Firebase Console configuration
   - APNs setup for iOS
   - Emulator configuration
   - Troubleshooting guide

3. **AUTH_REFACTOR_PLAN.md**
   - Original refactor plan
   - Migration strategy
   - UserProfile model design

4. **REMAINING_UPDATES.md**
   - Outstanding tasks
   - Deployment checklist

---

## 🎯 Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Email Verification | ✅ Complete | Auto-checks every 3s |
| Phone Verification | ⚠️ Needs Setup | Code ready, Firebase config needed |
| Privacy Policy | ✅ Complete | Full screen with acceptance |
| Survey | ✅ Complete | Placeholder, ready for real survey |
| Flow Management | ✅ Complete | Centralized in OnboardingFlowManager |
| Documentation | ✅ Complete | All guides created |

**Next:** Configure Firebase Phone Auth (see FIREBASE_AUTH_2FA_SETUP.md)

---

## 📞 Quick Reference

**Get SHA Keys:**
```bash
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker/android
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android | grep SHA
```

**Test the Flow:**
```bash
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker
flutter run
```

**Add Test Phone (Firebase Console):**
- Go to: Authentication → Sign-in method → Phone → Test numbers
- Add: `+1 650-555-1234` with code `123456`

---

**Ready to test! 🚀** Start with FIREBASE_AUTH_2FA_SETUP.md for step-by-step setup.


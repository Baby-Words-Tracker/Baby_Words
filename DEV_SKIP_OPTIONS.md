# Dev Skip Options Guide

**Created:** October 8, 2025  
**Purpose:** Quick reference for development skip options

---

## 🚧 Development Skip Features

### **1. Email Verification Skip**

**Location:** Email Verification Page

**Button:** "Skip for now (DEV ONLY)"

**What it does:**
- Sets a debug flag in `OnboardingFlowManager`
- Skips email verification check in debug mode only
- Automatically disabled in production builds

**How it works:**
```dart
OnboardingFlowManager.skipEmailVerification();
// AuthGate will now skip email verification step
```

**Console output:**
```
🚧 DEV: Email verification skipped
```

---

### **2. Phone Verification Skip**

**Location:** Phone Verification Page

**Button:** "Skip for now (set up later in settings)"

**What it does:**
- Marks 2FA as enabled in UserProfile (without actual phone verification)
- Allows proceeding to next step

**Use case:** 
- Testing flow without SMS
- SHA key issues
- Firebase Phone Auth not configured

---

### **3. Add First Child Skip**

**Location:** Add First Child Page (Tutorial)

**Button:** "Skip - I'll add a child later"

**What it does:**
- Navigates to home page without adding a child
- User can add child later in Settings
- Or receive shared child from another account

**Use case:**
- Testing child sharing functionality
- User wants to explore app first
- Child will be added by another parent account

---

## 📋 Quick Reference

| Step | Skip Button | Available In | Production |
|------|-------------|--------------|------------|
| Email Verification | ✅ Yes | Debug only | ❌ Disabled |
| Phone Verification | ✅ Yes | All builds | ✅ Enabled* |
| Privacy Policy | ❌ No | N/A | Must accept |
| Survey | ❌ No | N/A | Must complete |
| Add First Child | ✅ Yes | All builds | ✅ Enabled |

\* Phone skip is meant to be temporary - remove before production deployment

---

## 🛠️ Technical Details

### **Email Skip Implementation**

**File:** `lib/auth/onboarding_flow_manager.dart`

```dart
class OnboardingFlowManager {
  static bool _skipEmailVerification = false;
  
  static void skipEmailVerification() {
    if (kDebugMode) {  // Only works in debug mode!
      _skipEmailVerification = true;
    }
  }
  
  static OnboardingStep? getCurrentStep(...) {
    // Email check is skipped if flag is true
    if (!firebaseUser.emailVerified && !_skipEmailVerification) {
      return OnboardingStep.emailVerification;
    }
  }
}
```

**Safety:** 
- Only works when `kDebugMode == true`
- Automatically disabled in release builds
- Flag resets on app restart

---

### **Child Skip Implementation**

**File:** `lib/pages/tutorial/add_first_child_page.dart`

```dart
TextButton(
  onPressed: () {
    debugPrint('Tutorial: User skipped adding first child');
    Navigator.of(context).pushReplacementNamed('/');
  },
  child: const Text('Skip - I\'ll add a child later'),
)
```

**Note:** User will see empty state until they add a child

---

## 🎯 Usage Scenarios

### **Testing Complete Flow Quickly**

1. Register new account
2. **Skip email verification** → Click "Skip for now (DEV ONLY)"
3. **Skip phone verification** → Click "Skip for now"
4. Accept privacy policy
5. Complete survey (placeholder)
6. Welcome screen → "Get Started"
7. **Skip add child** → Click "Skip - I'll add a child later"
8. **Home page!** ✅

**Total time:** ~1 minute (vs ~5+ minutes with real verification)

### **Testing Child Sharing**

1. User A: Complete onboarding
2. User A: Add child "Emma"
3. User A: Share with User B's email
4. User B: Complete onboarding
5. User B: **Skip add child** (will receive Emma from User A)
6. User B: See Emma in their child list ✅

### **Testing Email Verification UI**

1. Register account
2. See email verification page
3. Test "Resend Email" button
4. Test auto-check (every 3 seconds)
5. **Don't want to check email?** → Click skip ✅

---

## ⚠️ Important Notes

### **Email Skip is Debug Only**

```dart
static void skipEmailVerification() {
  if (kDebugMode) {  // ← This prevents skip in production!
    _skipEmailVerification = true;
  }
}
```

Even if a user finds the button in production, it won't work.

### **Phone Skip Should Be Removed**

The phone skip is currently available in all builds. **Remove before production:**

```dart
// In phone_verification_page.dart
// TODO: Remove this button before production deployment
TextButton(
  onPressed: _skipFor2FANow,
  child: const Text('Skip for now (set up later in settings)'),
)
```

### **Child Skip is Permanent Feature**

The child skip is a legitimate feature for:
- Users receiving shared children
- Users wanting to explore app first
- Multiple scenarios where child creation is deferred

**Keep this in production!** ✅

---

## 🔄 Resetting Skip Flags

**Email skip resets automatically** when you:
- Restart the app
- Hot reload (flag is static, resets on reload)

**To re-test email verification:**
1. Restart app
2. Email verification will be checked again

---

## 📝 Console Debugging

**Email skip:**
```
🚧 DEV: Email verification skipped
NewAuthGate: Onboarding step: Phone Verification
```

**Phone skip:**
```
PhoneVerificationPage: 2FA enabled (skipped for dev)
NewAuthGate: Onboarding step: Privacy Policy
```

**Child skip:**
```
Tutorial: User skipped adding first child
NewAuthGate: Needs tutorial: false
[Shows HomePage with no children]
```

---

## ✅ Best Practices

### **During Development**

- ✅ Use skip buttons to test flow quickly
- ✅ Test with real verification occasionally (ensure it works)
- ✅ Keep skip buttons visible for easy access

### **Before Production**

- [ ] Remove phone skip button (or gate with debug flag)
- [ ] Keep email skip (debug-only, safe in production)
- [ ] Keep child skip (legitimate feature)
- [ ] Test production build without skip options

### **Code Review**

Look for:
```dart
// BAD: Skip available in production
TextButton(child: Text('Skip'), onPressed: ...)

// GOOD: Skip gated by debug mode
if (kDebugMode) {
  TextButton(child: Text('Skip (DEV)'), ...)
}
```

---

## 🎨 UI Changes

### **Email Verification Page**

**Before:**
- ✅ Resend Email button
- ✅ "I've Verified My Email" button ← **REMOVED**

**After:**
- ✅ Resend Email button
- ✅ "Skip for now (DEV ONLY)" button ← **NEW**

**Why:** Auto-check works perfectly now, so manual check button was redundant.

### **Add First Child Page**

**Before:**
- ✅ Add Child & Continue button

**After:**
- ✅ Add Child & Continue button
- ✅ "Skip - I'll add a child later" button ← **NEW**

**Why:** Allows users to defer child creation (useful for sharing scenarios).

---

## 🚀 Quick Start

**Fast test flow:**
```bash
flutter run

# In app:
1. Register → test@example.com
2. [Email] → Click "Skip for now (DEV ONLY)"
3. [Phone] → Click "Skip for now"
4. [Privacy] → Accept
5. [Survey] → Complete (placeholder)
6. [Welcome] → Get Started
7. [Add Child] → Click "Skip"
8. [Home] → You're in! 🎉
```

**Time:** < 1 minute

---

**Happy testing! 🚧**


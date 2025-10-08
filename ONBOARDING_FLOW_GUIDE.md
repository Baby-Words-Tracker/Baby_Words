# Onboarding Flow Guide

**Created:** October 8, 2025  
**Status:** ✅ Complete  
**Version:** 1.0

---

## 🎯 Overview

This document describes the new centralized onboarding flow for parent users (mobile). The flow is designed to be:
- **Easy to understand** - Clear progression through steps
- **Easy to maintain** - Centralized logic in `OnboardingFlowManager`
- **Easy to modify** - Add/remove/reorder steps by editing one file

---

## 📋 Onboarding Steps

For **parent users on mobile**, the onboarding flow consists of:

1. **Email Verification** ✉️
   - User receives verification email
   - Must click link in email
   - Auto-checks for verification every 3 seconds
   
2. **Phone Verification (2FA)** 📱
   - User enters phone number with country code
   - Receives SMS verification code
   - Enters code to verify
   - Phone number saved to UserProfile
   - Can skip for now (temporary)
   
3. **Privacy Policy** 📜
   - User reads privacy policy summary
   - Must check "I have read and understand" checkbox
   - Can view full policy in browser
   - Must accept to continue
   
4. **Research Survey** 📊
   - Required by IRB
   - Currently shows placeholder
   - Will be replaced with actual survey later
   
5. **App Access** ✅
   - All steps completed
   - User can access the app

---

## 🏗️ Architecture

### Core Components

#### 1. **OnboardingFlowManager** (`lib/auth/onboarding_flow_manager.dart`)

Centralized logic for determining which step a user is on.

```dart
// Get current step
final step = OnboardingFlowManager.getCurrentStep(
  firebaseUser: user,
  userProfile: profile,
);

// Check if onboarding is complete
final isComplete = OnboardingFlowManager.isOnboardingComplete(
  firebaseUser: user,
  userProfile: profile,
);

// Get progress (0.0 to 1.0)
final progress = OnboardingFlowManager.getProgress(
  firebaseUser: user,
  userProfile: profile,
);
```

**Key Methods:**
- `getCurrentStep()` - Returns the next incomplete step
- `isOnboardingComplete()` - Returns true if all steps done
- `getProgress()` - Returns completion percentage
- `getDebugStatus()` - Returns debug string for logging

#### 2. **OnboardingStep Enum**

Defines all possible onboarding steps:

```dart
enum OnboardingStep {
  emailVerification,
  phoneVerification,
  privacyPolicy,
  survey,
  completed;
}
```

Each step has:
- `displayName` - Human-readable name
- `icon` - Material icon for UI

#### 3. **Step Pages**

Individual pages for each onboarding step:

- `EmailVerificationPage` - Email verification
- `PhoneVerificationPage` - Phone/2FA setup
- `PrivacyPolicyPage` - Privacy policy acceptance
- `RequiredSurveyPage` - Research survey (existing)

#### 4. **NewAuthGate** (Updated)

The main auth gate now uses `OnboardingFlowManager` to determine which screen to show:

```dart
final onboardingStep = OnboardingFlowManager.getCurrentStep(
  firebaseUser: user,
  userProfile: profile,
);

switch (onboardingStep) {
  case OnboardingStep.emailVerification:
    return const EmailVerificationPage();
  case OnboardingStep.phoneVerification:
    return const PhoneVerificationPage();
  case OnboardingStep.privacyPolicy:
    return const PrivacyPolicyPage();
  case OnboardingStep.survey:
    return const RequiredSurveyPage();
  case OnboardingStep.completed:
    // Show home screen
    break;
}
```

---

## 🔄 Flow Logic

### How Steps Are Determined

The `OnboardingFlowManager.getCurrentStep()` checks conditions **in order**:

```dart
// 1. Email verification (Firebase Auth)
if (!firebaseUser.emailVerified) {
  return OnboardingStep.emailVerification;
}

// 2. Phone verification / 2FA
if (!userProfile.twoFactorEnabled) {
  return OnboardingStep.phoneVerification;
}

// 3. Privacy policy
if (!userProfile.acceptedPrivacyPolicy) {
  return OnboardingStep.privacyPolicy;
}

// 4. Survey (parents only)
if (userProfile.requiresSurvey) {
  return OnboardingStep.survey;
}

// All done!
return OnboardingStep.completed;
```

### Step Completion

Each step page is responsible for marking itself complete:

**Email Verification:**
- Automatically detected when user clicks email link
- Firebase Auth `emailVerified` flag updated
- AuthGate auto-advances

**Phone Verification:**
- User enters phone and code
- Calls `userModelService.enable2FA(phoneNumber: phone)`
- Updates `UserProfile.twoFactorEnabled` and `phoneNumber`
- AuthGate auto-advances

**Privacy Policy:**
- User checks "I have read" checkbox
- Clicks "Accept and Continue"
- Calls `userModelService.acceptPrivacyPolicy()`
- Updates `UserProfile.acceptedPrivacyPolicy`
- AuthGate auto-advances

**Survey:**
- User completes survey (placeholder for now)
- Calls `userModelService.completeSurvey()`
- Updates `UserProfile.surveyCompleted`
- AuthGate auto-advances

---

## 🛠️ How to Modify the Flow

### Adding a New Step

1. **Add to enum** in `onboarding_flow_manager.dart`:
   ```dart
   enum OnboardingStep {
     emailVerification,
     phoneVerification,
     privacyPolicy,
     biometricSetup,  // NEW STEP
     survey,
     completed;
   }
   ```

2. **Add check logic** in `getCurrentStep()`:
   ```dart
   // After privacy policy check
   if (!userProfile.biometricEnabled) {
     return OnboardingStep.biometricSetup;
   }
   ```

3. **Create page** `lib/pages/onboarding/biometric_setup_page.dart`

4. **Add to AuthGate** switch statement:
   ```dart
   case OnboardingStep.biometricSetup:
     return const BiometricSetupPage();
   ```

### Removing a Step

1. **Remove from enum** in `onboarding_flow_manager.dart`
2. **Remove check** from `getCurrentStep()`
3. **Remove page** from `lib/pages/onboarding/`
4. **Remove from AuthGate** switch statement

### Reordering Steps

Simply reorder the checks in `getCurrentStep()`. The first condition that returns `false` determines the current step.

Example - Put survey before privacy policy:
```dart
// Survey first
if (userProfile.requiresSurvey) {
  return OnboardingStep.survey;
}

// Then privacy policy
if (!userProfile.acceptedPrivacyPolicy) {
  return OnboardingStep.privacyPolicy;
}
```

---

## 📱 User Experience

### Email Verification Screen

**Features:**
- Shows user's email address
- Step-by-step instructions
- Auto-checks verification status every 3 seconds
- "Resend Email" button
- "I've Verified" manual check button
- "Sign Out" option

**User Actions:**
1. Receives welcome email
2. Clicks verification link
3. Returns to app
4. Auto-advances to next step

### Phone Verification Screen

**Features:**
- Phone number input with country code
- SMS code verification
- Automatic Firebase Phone Auth
- Phone number saved to profile
- "Skip for now" option (temporary)
- Help text about 2FA security

**User Actions:**
1. Enters phone number (+1 234 567 8900)
2. Clicks "Send Code"
3. Receives SMS
4. Enters 6-digit code
5. Clicks "Verify Code"
6. Auto-advances to next step

### Privacy Policy Screen

**Features:**
- Privacy policy summary
- "Read Full Policy" link (opens browser)
- "I have read and understand" checkbox
- Accept/Decline buttons
- Policy version displayed
- Decline triggers sign out

**User Actions:**
1. Reads summary
2. Optionally views full policy
3. Checks "I have read" checkbox
4. Clicks "Accept and Continue"
5. Auto-advances to next step

### Survey Screen

**Features:**
- IRB requirement explanation
- Placeholder survey content
- "Complete Survey" button
- Can't skip or go back
- Will be replaced with real survey

**User Actions:**
1. Reads instructions
2. Completes survey (placeholder)
3. Clicks "Complete Survey"
4. Auto-advances to app

---

## 🔐 Security & Privacy

### Email Verification
- Uses Firebase Auth's built-in email verification
- Prevents unverified users from accessing app
- Email verification link expires after period

### Phone Verification (2FA)
- Uses Firebase Phone Auth
- SMS code sent to user's phone
- Phone credential linked to user account
- Phone number stored in UserProfile
- Enhances account security

### Privacy Policy
- Version tracked in UserProfile
- Acceptance date recorded
- User must explicitly check and accept
- Can decline (triggers sign out)

### Survey
- Required by IRB for research
- Completion tracked in UserProfile
- Survey version recorded
- Date of completion saved

---

## 🧪 Testing

### Test New User Flow

1. **Create test account:**
   ```
   Email: test@example.com
   Password: testpass123
   ```

2. **Verify each step:**
   - ✅ Email verification screen appears
   - ✅ Check inbox and click verification link
   - ✅ Phone verification screen appears
   - ✅ Enter phone and verify code
   - ✅ Privacy policy screen appears
   - ✅ Check checkbox and accept
   - ✅ Survey screen appears
   - ✅ Complete survey
   - ✅ Home screen appears

3. **Test edge cases:**
   - ❌ Try to skip steps (should not be possible)
   - ❌ Decline privacy policy (should sign out)
   - ✅ Resend verification email
   - ✅ Resend phone code
   - ✅ Sign out during onboarding (should restart)

### Debug Logging

All steps log their progress:

```
NewAuthGate: Onboarding step: Email Verification
OnboardingFlow: Step=Email Verification, Progress=0%

EmailVerificationPage: Verification email sent
EmailVerificationPage: Email verified!

NewAuthGate: Onboarding step: Phone Verification
OnboardingFlow: Step=Phone Verification, Progress=25%

PhoneVerificationPage: Code sent to +1234567890
PhoneVerificationPage: 2FA enabled in UserProfile

... etc
```

---

## 🚀 Future Enhancements

### Short Term
- [ ] Replace survey placeholder with real survey
- [ ] Add progress indicator to show completion %
- [ ] Add "Resume later" option (save progress)
- [ ] Improve error handling and retry logic

### Medium Term
- [ ] Add biometric authentication option
- [ ] Add profile photo upload step
- [ ] Add tutorial/walkthrough after onboarding
- [ ] Add onboarding analytics tracking

### Long Term
- [ ] Personalized onboarding based on user type
- [ ] A/B testing different onboarding flows
- [ ] Gamification (badges, progress rewards)
- [ ] Social proof (users completed, testimonials)

---

## 📚 Key Files

```
lib/
├── auth/
│   ├── onboarding_flow_manager.dart         # Core flow logic
│   ├── user_profile_model_service.dart      # Profile management
│   └── authentication_service.dart          # Firebase Auth
│
├── pages/
│   ├── new_auth_gate.dart                   # Main auth gate
│   ├── onboarding/
│   │   ├── email_verification_page.dart     # Step 1
│   │   ├── phone_verification_page.dart     # Step 2
│   │   └── privacy_policy_page.dart         # Step 3
│   └── required_survey_page.dart            # Step 4
│
├── data/
│   ├── models/
│   │   └── user_profile.dart                # UserProfile model
│   └── services/
│       └── user_profile_service.dart        # Firestore operations
│
└── util/
    └── policies_and_consent/
        └── privacy_policy_information.dart  # Policy content
```

---

## 🐛 Troubleshooting

### User stuck on email verification
**Cause:** Email not verified or user didn't reload  
**Fix:** 
1. Check spam folder
2. Click "Resend Email"
3. Click "I've Verified My Email" to manual check

### Phone verification fails
**Cause:** Invalid phone format, quota exceeded, or network issue  
**Fix:**
1. Ensure phone has country code (+1)
2. Check Firebase console for quota limits
3. Try "Resend Code"
4. Temporarily use "Skip for now"

### Privacy policy not accepting
**Cause:** Checkbox not checked  
**Fix:**
1. Ensure "I have read" is checked
2. Click "Accept and Continue"

### Survey not completing
**Cause:** Network error or service issue  
**Fix:**
1. Check network connection
2. Check Firebase console for errors
3. Restart app and try again

---

## 📞 Support

For issues with the onboarding flow:
1. Check debug logs in console
2. Review Firestore rules for permission errors
3. Check Firebase Auth quotas and limits
4. Review this guide for troubleshooting

---

**Happy Onboarding! 🎉**


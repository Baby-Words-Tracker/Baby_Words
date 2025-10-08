# Email Verification Testing Guide

**Quick Guide:** How to get past the email verification screen during testing

---

## 🎯 Quick Answer

### **Option 1: Use Real Email (Recommended for Testing)**

1. **Check your email inbox** for the verification email
   - Subject: "Verify your email for Baby Words Tracker"
   - From: noreply@baby-words-tracker.firebaseapp.com

2. **Click the verification link** in the email

3. **Return to the app** - it will auto-detect verification within 3 seconds

4. **Or click "I've Verified My Email"** button for immediate check

### **Option 2: Use Firebase Console (Quick Testing)**

If you want to skip email verification during development:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Navigate to **Authentication** → **Users**
3. Find your test user
4. Click the **3-dot menu** → **Edit user**
5. Check **"Email verified"**
6. Click **Save**
7. Return to app - it will detect verification

### **Option 3: Disable Email Verification (Development Only)**

Temporarily skip email verification by modifying the flow:

**File:** `lib/auth/onboarding_flow_manager.dart`

```dart
// Comment out email verification check (DEVELOPMENT ONLY!)
static OnboardingStep? getCurrentStep({
  required User? firebaseUser,
  required UserProfile? userProfile,
}) {
  if (firebaseUser == null || userProfile == null) {
    return null;
  }
  
  if (!userProfile.isParent) {
    return OnboardingStep.completed;
  }
  
  // TEMPORARILY DISABLED FOR TESTING
  // if (!firebaseUser.emailVerified) {
  //   return OnboardingStep.emailVerification;
  // }
  
  // Continue with other checks...
  if (!userProfile.twoFactorEnabled) {
    return OnboardingStep.phoneVerification;
  }
  // ...
}
```

**⚠️ Remember to re-enable before production!**

---

## 🐛 Troubleshooting

### **Not Receiving Email?**

**Check these:**
1. **Spam folder** - Verification emails often land there
2. **Email address** - Make sure it's correct
3. **Firebase quotas** - Check Firebase Console for quota limits
4. **Authorized domains** - Check Firebase Console → Authentication → Settings → Authorized domains

**Quick fix:**
- Click **"Resend Email"** button in the app
- Wait 1-2 minutes for delivery

### **Email Link Not Working?**

**Try:**
1. Copy the full URL from email
2. Open in browser manually
3. Check if URL is complete (not truncated)
4. Try on desktop if testing on mobile

### **Screen Still Shows After Verification?**

**Wait 3 seconds** - The app auto-checks every 3 seconds

**Or** click **"I've Verified My Email"** for immediate check

**Still stuck?** Check console logs:
```
EmailVerificationPage: Email verified! ✅
```

If you see this, the app detected it. If not:
1. Restart the app
2. Sign out and sign in again
3. Check Firebase Console that user is marked as verified

---

## 🔧 Testing Tips

### **During Development:**

**Use a catch-all email domain** if you have one:
- `test1@yourdomain.com`
- `test2@yourdomain.com`
- All go to same inbox

**Or use Gmail +tags:**
- `yourname+test1@gmail.com`
- `yourname+test2@gmail.com`
- All go to `yourname@gmail.com`

### **Automated Testing:**

For CI/CD or automated testing, you'll want to:
1. Use Firebase Admin SDK to mark users as verified
2. Or skip email verification in test mode
3. Or use Firebase emulators with auto-verification

---

## 📝 What Changed (Screen Flashing Fix)

### **Before:**
- Screen would flash/rebuild every 3 seconds during auto-check
- Loading indicator would appear and disappear

### **After:**
- Auto-checks happen **silently in background**
- Screen only rebuilds for **manual checks** (when you click button)
- Static "Auto-checking every 3 seconds" message (no flashing)

### **Technical Details:**

```dart
// Only trigger setState for manual checks, not auto-checks
final isManualCheck = _autoCheckTimer == null || !_autoCheckTimer!.isActive;

if (isManualCheck && mounted) {
  setState(() {
    _isChecking = true;
  });
}
```

This prevents the UI from rebuilding on every background check.

---

## 🚀 Production Considerations

### **Email Deliverability:**

For production, ensure:
- [ ] Configure custom email templates in Firebase
- [ ] Set up SPF and DKIM records
- [ ] Use custom domain for sender address
- [ ] Test with different email providers (Gmail, Outlook, Yahoo)
- [ ] Monitor bounce rates in Firebase Console

### **User Experience:**

- [ ] Show estimated delivery time (1-2 minutes)
- [ ] Explain to check spam folder
- [ ] Provide support contact if issues
- [ ] Allow changing email if typo
- [ ] Rate limit resend button (currently no limit)

---

## 📧 Console Output Guide

When testing, watch for these console messages:

**Email sent successfully:**
```
📧 EmailVerificationPage: Verification email sent to test@example.com
📧 Check your email inbox and click the verification link
📧 After clicking the link, return to this screen
```

**Email verified:**
```
EmailVerificationPage: Email verified! ✅
```

**Error sending:**
```
❌ EmailVerificationPage: Error sending verification email: [error details]
```

---

## 🎯 Quick Commands

### **Check User Status in Firebase:**
```bash
# Open Firebase Console
open https://console.firebase.google.com
```

### **Clear App Data (Fresh Start):**
```bash
# Android
adb shell pm clear com.example.baby_words_tracker

# iOS
# Delete and reinstall app
```

### **Check Email in Console:**
Look for these logs when email is sent:
```
flutter: 📧 EmailVerificationPage: Verification email sent to YOUR_EMAIL
```

---

## 🔍 Common Scenarios

### **Scenario 1: Testing with Real Email**
1. Register: `yourname+test1@gmail.com`
2. Check Gmail inbox
3. Click verification link
4. Return to app → Auto-advances ✅

### **Scenario 2: Quick Testing (Skip Email)**
1. Register with any email
2. Open Firebase Console
3. Mark user as verified manually
4. Return to app → Auto-advances ✅

### **Scenario 3: Development (Disable Temporarily)**
1. Comment out email check in `onboarding_flow_manager.dart`
2. Register with any email
3. Skip directly to phone verification ✅
4. **Don't forget to re-enable!**

---

## ✅ Fixed Issues

- [x] Screen flashing during auto-check
- [x] Added better console logging
- [x] Static UI indicator (no rebuilding)
- [x] Manual check still shows loading state
- [x] Auto-check stops after verification detected

---

**Pro Tip:** Use Gmail +tags (`yourname+test1@gmail.com`) to create unlimited test emails that all go to the same inbox!


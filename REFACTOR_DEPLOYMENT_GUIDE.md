# Auth Refactor - Deployment Guide

**Status:** ✅ Code Complete - Ready for Testing  
**Progress:** 80% Complete

---

## 🎉 What's Been Completed

### ✅ Core Implementation (100%)
1. **UserProfile Model** - Complete with platform enforcement
2. **UserProfileService** - With retry logic and error handling
3. **Unit Tests** - Full test coverage for UserProfile
4. **Cloud Functions** - Updated roles.js and onCreate
5. **Migration Function** - Ready to migrate existing users
6. **Firestore Rules** - Complete security rules for UserProfile
7. **NewUserModelService** - Clean auth logic using UserProfile
8. **NewAuthGate** - With platform checks and survey gates
9. **RequiredSurveyPage** - Placeholder for survey
10. **Main.dart** - Wired everything together

---

## 📋 Testing & Deployment Steps

### Step 1: Deploy Cloud Functions (Required First)

**Deploy the updated functions:**
```bash
cd /Users/chase/Repositories/Baby_Words/firebase-project
firebase deploy --only functions
```

**What this does:**
- Updates `addDefaultClaim` to create UserProfile on new user registration
- Deploys `migrateToUserProfile` function for data migration
- Updates role/status helpers

**Verify deployment:**
- Check Firebase Console → Functions
- Should see: `addDefaultClaim`, `migrateToUserProfile`, and existing functions

---

### Step 2: Deploy Firestore Rules

**Deploy the new security rules:**
```bash
cd /Users/chase/Repositories/Baby_Words/firebase-project
firebase deploy --only firestore:rules
```

**What this does:**
- Enables UserProfile collection access
- Enforces platform restrictions
- Requires survey for parents to create children
- Makes old collections read-only

**Verify deployment:**
- Firebase Console → Firestore → Rules
- Check that UserProfile rules are active

---

### Step 3: Test in Emulator (Recommended)

**Start Firebase emulators:**
```bash
cd /Users/chase/Repositories/Baby_Words/firebase-project
firebase emulators:start
```

**Run Flutter app against emulator:**
```bash
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker
# Make sure useEmulator is set in your code
flutter run
```

**Test these flows:**
1. ✅ Register new account (email/password)
   - Should create UserProfile
   - Should show privacy policy
   - Should show survey
   - Should navigate to home

2. ✅ Sign in existing user (if any test accounts)
   - Should load profile
   - Should check requirements

3. ✅ Platform enforcement
   - Parent on web → Should see "Wrong Platform" screen
   - Researcher on mobile → Should see "Wrong Platform" screen

4. ✅ Survey requirement
   - Parent without survey → Should block until complete
   - After completing → Should allow access

---

### Step 4: Run Migration (Production)

**IMPORTANT: Test migration in dry-run mode first!**

**Method 1: Using Firebase CLI (if you have curl)**
```bash
# Get your project ID
firebase use

# Dry run first (safe - won't modify data)
curl -X POST \
  https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/migrateToUserProfile \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer $(firebase login:ci)' \
  -d '{"data": {"dryRun": true}}'

# If dry run looks good, run for real
curl -X POST \
  https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/migrateToUserProfile \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer $(firebase login:ci)' \
  -d '{"data": {"dryRun": false}}'
```

**Method 2: Using Firebase Console**
1. Go to Firebase Console → Functions
2. Find `migrateToUserProfile`
3. Click "Test Function"
4. Send: `{"data": {"dryRun": true}}` (test first)
5. Check logs for results
6. Send: `{"data": {"dryRun": false}}` (run for real)

**What the migration does:**
- Reads all Parent documents → Creates UserProfile (role: parent)
- Reads all Researcher documents → Creates UserProfile (role: researcher)
- Preserves all data (privacy policy, survey status, childIDs, etc.)
- Adds metadata (migratedFrom, migratedAt)
- Skips already-migrated users

**Verify migration:**
```bash
# Check UserProfile collection in Firestore Console
# Should see all users migrated with correct roles
```

---

### Step 5: Deploy Flutter App

**Build and deploy:**

**For Web:**
```bash
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker
flutter build web
firebase deploy --only hosting
```

**For Mobile:**
```bash
# iOS
flutter build ios --release
# Then upload to App Store Connect

# Android
flutter build appbundle --release
# Then upload to Play Console
```

---

### Step 6: Verify Everything Works

**Test these scenarios in production:**

1. **New User Registration:**
   - [ ] Can register with email/password
   - [ ] Can register with Google OAuth
   - [ ] UserProfile is created automatically
   - [ ] Privacy policy appears
   - [ ] Survey appears (for parents)
   - [ ] Navigates to home after all complete

2. **Existing User Sign-In:**
   - [ ] Can sign in with credentials
   - [ ] Profile loads correctly
   - [ ] Already-accepted privacy doesn't re-prompt
   - [ ] Already-completed survey doesn't re-prompt
   - [ ] Navigates to appropriate home (parent/researcher)

3. **Platform Enforcement:**
   - [ ] Parents can't access from web
   - [ ] Researchers can't access from mobile
   - [ ] Admins can access both
   - [ ] Error message is clear

4. **Survey Gate:**
   - [ ] Parents without survey see RequiredSurveyPage
   - [ ] Can't skip or go back
   - [ ] After completion, can access app
   - [ ] Researchers don't see survey

5. **Data Integrity:**
   - [ ] ChildIDs preserved
   - [ ] Privacy policy status preserved
   - [ ] All user data intact

---

## 🔄 Rollback Plan (If Needed)

**If something goes wrong, here's how to rollback:**

### Rollback Cloud Functions
```bash
cd /Users/chase/Repositories/Baby_Words/firebase-project
# Deploy previous version
git checkout HEAD~1 functions/
firebase deploy --only functions
```

### Rollback Firestore Rules
```bash
cd /Users/chase/Repositories/Baby_Words/firebase-project
# Deploy previous rules
git checkout HEAD~1 firestore.rules
firebase deploy --only firestore:rules
```

### Rollback Flutter App
```bash
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker
git checkout HEAD~1 lib/main.dart
# Or switch back to old AuthGate in main.dart:
# Change: NewAuthGate.routeName → AuthGate.routeName
```

**Important:** UserProfile collection data is safe - it's additive, won't interfere with old system

---

## 🐛 Troubleshooting

### Issue: User stuck on loading screen
**Cause:** UserProfile not created  
**Fix:** Check Cloud Functions logs, ensure `addDefaultClaim` ran successfully

### Issue: Permission denied errors
**Cause:** Firestore rules not deployed  
**Fix:** Run `firebase deploy --only firestore:rules`

### Issue: Platform mismatch error on wrong platform
**Cause:** This is expected behavior!  
**Fix:** User needs to use correct platform (parent=mobile, researcher=web)

### Issue: Migration failed for some users
**Cause:** Missing auth data or malformed documents  
**Fix:** Check migration function logs, manually create UserProfile for failed users

### Issue: Old code still running
**Cause:** Flutter app not rebuilt  
**Fix:** Run `flutter clean && flutter run`

---

## 📊 Monitoring

**Things to monitor after deployment:**

1. **Cloud Function Logs:**
   ```bash
   firebase functions:log
   ```
   Look for: User creation, profile creation, errors

2. **Firestore Usage:**
   - Check UserProfile collection is populating
   - Verify old collections are read-only (no new writes)

3. **User Reports:**
   - Registration issues
   - Sign-in problems
   - Platform access errors

4. **Error Tracking:**
   - Set up Crashlytics/Sentry for production errors
   - Monitor auth failure rates

---

## ✅ Success Criteria

After deployment, verify:
- [ ] All existing users migrated successfully
- [ ] New users create UserProfile automatically
- [ ] Platform enforcement works correctly
- [ ] Survey gate works for parents
- [ ] Privacy policy flow works
- [ ] No production errors for 24 hours
- [ ] Old Parent/Researcher collections have no new writes

---

## 🗑️ Cleanup (After 30 Days)

Once verified everything works:

1. **Delete old Dart files:**
   ```bash
   cd /Users/chase/Repositories/Baby_Words/baby_words_tracker
   rm lib/data/models/parent.dart
   rm lib/data/models/researcher.dart
   rm lib/data/models/i_user_model.dart
   rm lib/data/services/parent_data_service.dart
   rm lib/data/services/researcher_data_service.dart
   rm lib/data/services/general_user_service.dart
   rm lib/util/user_roles.dart
   rm lib/util/user_type.dart
   rm lib/auth/user_model_service.dart
   rm lib/pages/auth_gate.dart
   ```

2. **Remove old providers from main.dart:**
   - Remove ParentDataService provider
   - Remove ResearcherDataService provider
   - Remove GeneralUserService provider
   - Remove old UserModelService provider

3. **Delete old Firestore collections:**
   - Export Parent collection (backup)
   - Export Researcher collection (backup)
   - Delete old collections via console

4. **Update Firestore rules:**
   - Remove legacy collection rules
   - Remove backward compatibility sections

---

## 📝 Notes

- **2FA:** Required for ALL users (not yet implemented, placeholder ready)
- **Survey:** Placeholder screen - integrate real survey from other branch
- **Demo Mode:** Fully supported with isolated `demo_UserProfile` collection
- **Platform:** Enforced at auth level (parent=mobile, researcher=web, admin=both)

---

**Questions? Check the logs or contact the dev team!** 🚀


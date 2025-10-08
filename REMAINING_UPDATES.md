# Remaining Updates for UserProfile Migration

## ✅ What's Working Now
- ✅ New user registration creates UserProfile
- ✅ Custom claims set correctly
- ✅ Privacy policy saves to UserProfile
- ✅ Emulator connection works
- ✅ Platform access enforcement
- ✅ Survey requirement enforcement
- ✅ Cloud Functions create UserProfile on user creation

## 🔄 Downstream Changes Needed

### 1. **Child Association** (HIGH PRIORITY)
Currently, when a parent adds a child, it might try to update the old `Parent` collection.

**Files to Update:**
- `lib/data/services/child_data_service.dart` - Update child creation to add childID to UserProfile
- Check any place that updates `Parent.childIDs` → should update `UserProfile.childIDs`

**Search for:**
```bash
grep -r "childIDs" lib/
grep -r "addChild" lib/
```

### 2. **Authentication Checks Throughout App**
Some screens might still check the old `UserModelService` instead of `NewUserModelService`.

**Files to Check:**
- `lib/pages/home_page.dart` - Ensure uses NewUserModelService
- `lib/pages/profile_page.dart` - Update profile display
- `lib/pages/admin_page.dart` - Admin checks
- Any page that checks user role/type

**Search for:**
```bash
grep -r "UserModelService" lib/pages/
grep -r "userType" lib/pages/
```

### 3. **Role Management UI**
If there's any UI for changing user roles (admin panel), it needs updating.

**Files to Check:**
- `lib/pages/admin_page.dart` - Admin role assignment
- Any researcher management screens

### 4. **Survey Completion Flow**
The placeholder survey screen needs to save completion to UserProfile.

**File to Update:**
- `lib/pages/required_survey_page.dart` - Add actual survey logic
- Update `UserProfile.surveyCompleted` when done

### 5. **2FA Implementation** (FUTURE)
Currently just logs that 2FA is required. Need to implement:
- 2FA enrollment screen
- 2FA verification flow
- Update `UserProfile.twoFactorEnabled` when complete

### 6. **Demo Mode** (OPTIONAL)
If keeping demo mode, ensure it works with UserProfile:
- `demo_UserProfile` collection access
- Demo status in UserProfile

### 7. **Data Export/Import**
If there are features to export user data:
- Update to export from UserProfile instead of Parent/Researcher
- Update any CSV/data export utilities

## 📋 Deployment Plan

### Phase 1: Pre-Deployment Testing (NOW)
- [x] Test new user registration in emulator
- [x] Test privacy policy acceptance
- [x] Verify UserProfile creation
- [ ] Test child creation/association
- [ ] Test existing user login (after migration)
- [ ] Test role-based access (parent, researcher, admin)
- [ ] Test platform restrictions (mobile vs web)

### Phase 2: Production Deployment

#### Step 1: Deploy Cloud Functions (15 min)
```bash
cd /Users/chase/Repositories/Baby_Words/firebase-project
firebase deploy --only functions
```
**Actions:**
- Confirm deletion of old functions (giveDemoClaim, removeDemoClaim, setTypeClaim)
- Verify deployment success
- Check logs for errors

#### Step 2: Deploy Firestore Rules (5 min)
```bash
firebase deploy --only firestore:rules
```
**Actions:**
- Verify rules deployed successfully
- Test access in production (create test account)

#### Step 3: Run Migration (30 min)
**Before migration:**
1. Backup production Firestore data
2. Test migration in emulator first with real data snapshot

**Run migration:**
```bash
# From Firebase Console or via callable function:
# 1. Sign in as admin user
# 2. Call migrateToUserProfile with dryRun: true
# 3. Review results
# 4. Call migrateToUserProfile with dryRun: false
```

**Verify:**
- All users have UserProfile documents
- Custom claims correctly set
- Old Parent/Researcher data intact (read-only)
- No users lost

#### Step 4: Deploy Flutter App (45 min)
```bash
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker

# For Android
flutter build appbundle
# Upload to Google Play Console

# For iOS  
flutter build ipa
# Upload to App Store Connect

# For Web (if applicable)
flutter build web
firebase deploy --only hosting
```

#### Step 5: Monitor & Verify (24 hours)
- Monitor error logs in Firebase Console
- Check user reports
- Verify new registrations work
- Verify existing users can log in
- Watch for permission errors

### Phase 3: Post-Deployment (After 30 days)

#### Cleanup Old Collections (After verifying stability)
```javascript
// In Firestore rules, remove:
match /Parent/{parentId} { ... }
match /Researcher/{researcherId} { ... }
match /User/{userId} { ... }

// Optionally delete old collections after backing up
```

## 🔍 Quick Checks

### Check 1: Find Child Association Code
```bash
cd /Users/chase/Repositories/Baby_Words/baby_words_tracker
grep -r "Parent.*childIDs" lib/
grep -r "addChild" lib/
grep -r "ParentDataService" lib/
```

### Check 2: Find Role/Type Checks
```bash
grep -r "isParent" lib/ --include="*.dart"
grep -r "isResearcher" lib/ --include="*.dart"
grep -r "userType ==" lib/ --include="*.dart"
```

### Check 3: Find Old UserModelService Usage
```bash
grep -r "UserModelService" lib/pages/ --include="*.dart"
grep -r "context.read<UserModelService>" lib/ --include="*.dart"
```

## 🚨 Known Issues to Monitor

1. **Old UserModelService** - Still exists for backward compatibility but might cause confusion
2. **Parent/Researcher Collections** - Read-only, errors expected if code tries to write
3. **Demo Mode** - Simplified for now, may need refinement
4. **2FA** - Not implemented yet, just logs requirement
5. **Survey** - Placeholder screen, needs real implementation

## 📝 Next Immediate Tasks

1. **Search for child association code** - Ensure it updates UserProfile.childIDs
2. **Update any remaining UserModelService references** - Migrate to NewUserModelService
3. **Test migration in emulator with production data snapshot**
4. **Complete survey implementation** - Or decide to defer
5. **Decide on 2FA timeline** - Implement or defer

## 🎯 Critical Path to Production

**Must Do Before Production:**
1. ✅ Fix emulator connection
2. ✅ Fix privacy policy saving
3. ✅ Test new user registration
4. ⏳ Test child association
5. ⏳ Test existing user flow (need migration)
6. ⏳ Run migration in emulator
7. ⏳ Deploy functions + rules
8. ⏳ Run production migration
9. ⏳ Deploy app

**Can Defer:**
- 2FA implementation (just log for now)
- Full survey (use placeholder)
- Demo mode refinement
- Old collection cleanup (30 day buffer)


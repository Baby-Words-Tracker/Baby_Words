# Authentication Refactor Plan

**Date:** October 8, 2025  
**Status:** Ready to implement  
**Goal:** Clean up auth system before adding 2FA and survey requirements

---

## 🎯 Overview

This plan consolidates the messy role system and fixes remaining issues to create a solid foundation for 2FA and survey features.

**Estimated Time:** 2-3 days  
**Complexity:** Medium  
**Breaking Changes:** Yes, but no real users yet

---

## Phase 1: Role System Consolidation (Priority: HIGH)

### Current Mess

**THREE separate systems:**
```
Firebase Custom Claims (JS) → UserRole (Dart) → UserType (Dart) → Firestore Collections
     {parent: true}        →    parent (5)    →      parent      → Parent/{uid}
  {researcher: true}       →  researcher (3)  →    researcher    → Researcher/{uid}
    {admin: true}          →    admin (0)     →   (missing!)     → (none)
    {demo: true}           →  (separate)      →  (separate)      → demo_Parent/{uid}
```

### Proposed Clean System

**ONE unified system:**
```
Firebase Custom Claims → UserProfile (Firestore) → UI
  {role: "parent"}     →  UserProfile/{uid}     → HomePage
  {status: "active"}   →    - role: parent      
                       →    - status: active
                       →    - emailVerified
                       →    - surveyCompleted
                       →    - twoFactorEnabled
```

---

## 📋 Step-by-Step Refactor

### Step 1: Create New Data Models (1-2 hours)

#### 1.1 Create UserProfile Model

**File:** `baby_words_tracker/lib/data/models/user_profile.dart`

```dart
import 'package:baby_words_tracker/data/models/data_with_id.dart';

enum UserRole {
  admin,      // Full system access
  researcher, // Read all data
  parent;     // Manage own children
  
  int get priority {
    switch (this) {
      case admin: return 0;
      case researcher: return 3;
      case parent: return 5;
    }
  }
  
  bool canAccessData(UserRole targetRole) {
    return priority <= targetRole.priority;
  }
}

enum UserStatus {
  active,    // Normal user
  demo,      // Demo/sandbox mode
  suspended; // Temporarily disabled
}

class UserProfile {
  final String id;
  final UserRole role;
  final UserStatus status;
  
  // Contact info
  final String? email;
  final String? name;
  final String? phoneNumber;
  final String? institution; // For researchers
  
  // Auth state
  final bool emailVerified;
  final bool twoFactorEnabled;
  final DateTime? twoFactorEnabledAt;
  
  // Privacy & consent
  final bool acceptedPrivacyPolicy;
  final String? policyVersion;
  final DateTime? consentDate;
  
  // Survey (for parents)
  final bool surveyCompleted;
  final String? surveyVersion;
  final DateTime? surveyCompletedAt;
  
  // Parent-specific
  final List<String> childIDs;
  final LanguageCode? preferredLanguage;
  
  UserProfile({
    required this.id,
    required this.role,
    this.status = UserStatus.active,
    this.email,
    this.name,
    this.phoneNumber,
    this.institution,
    this.emailVerified = false,
    this.twoFactorEnabled = false,
    this.twoFactorEnabledAt,
    this.acceptedPrivacyPolicy = false,
    this.policyVersion,
    this.consentDate,
    this.surveyCompleted = false,
    this.surveyVersion,
    this.surveyCompletedAt,
    this.childIDs = const [],
    this.preferredLanguage,
  });
  
  // Helper getters
  bool get isParent => role == UserRole.parent;
  bool get isResearcher => role == UserRole.researcher;
  bool get isAdmin => role == UserRole.admin;
  bool get isDemoUser => status == UserStatus.demo;
  bool get isActive => status == UserStatus.active;
  
  bool get requiresSurvey => isParent && !surveyCompleted;
  bool get requires2FA => isResearcher || isAdmin;
  
  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'status': status.name,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'institution': institution,
      'emailVerified': emailVerified,
      'twoFactorEnabled': twoFactorEnabled,
      'twoFactorEnabledAt': twoFactorEnabledAt,
      'acceptedPrivacyPolicy': acceptedPrivacyPolicy,
      'policyVersion': policyVersion,
      'consentDate': consentDate,
      'surveyCompleted': surveyCompleted,
      'surveyVersion': surveyVersion,
      'surveyCompletedAt': surveyCompletedAt,
      'childIDs': childIDs,
      'preferredLanguage': preferredLanguage?.name,
    };
  }
  
  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      id: id,
      role: UserRole.values.byName(map['role'] ?? 'parent'),
      status: UserStatus.values.byName(map['status'] ?? 'active'),
      email: map['email'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      institution: map['institution'],
      emailVerified: map['emailVerified'] ?? false,
      twoFactorEnabled: map['twoFactorEnabled'] ?? false,
      twoFactorEnabledAt: map['twoFactorEnabledAt']?.toDate(),
      acceptedPrivacyPolicy: map['acceptedPrivacyPolicy'] ?? false,
      policyVersion: map['policyVersion'],
      consentDate: map['consentDate']?.toDate(),
      surveyCompleted: map['surveyCompleted'] ?? false,
      surveyVersion: map['surveyVersion'],
      surveyCompletedAt: map['surveyCompletedAt']?.toDate(),
      childIDs: List<String>.from(map['childIDs'] ?? []),
      preferredLanguage: map['preferredLanguage'] != null 
          ? LanguageCode.values.byName(map['preferredLanguage'])
          : null,
    );
  }
  
  factory UserProfile.fromDataWithId(DataWithId data) {
    return UserProfile.fromMap(data.data, data.id);
  }
}
```

#### 1.2 Create UserProfileService

**File:** `baby_words_tracker/lib/data/services/user_profile_service.dart`

```dart
import 'package:baby_words_tracker/data/models/user_profile.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:flutter/foundation.dart';

class UserProfileService extends ChangeNotifier {
  static const String collectionName = 'UserProfile';
  final FirestoreRepository _repository;
  
  UserProfileService({FirestoreRepository? repository})
      : _repository = repository ?? FirestoreRepository();
  
  // Create new user profile
  Future<UserProfile?> createUserProfile(UserProfile profile) async {
    try {
      await _repository.createWithId(
        collectionName,
        profile.id,
        profile.toMap(),
      );
      debugPrint('UserProfileService: Created profile for ${profile.id}');
      return profile;
    } catch (e) {
      debugPrint('UserProfileService: Error creating profile: $e');
      return null;
    }
  }
  
  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final data = await _repository.read(collectionName, userId);
      if (data != null) {
        return UserProfile.fromDataWithId(data);
      }
      return null;
    } catch (e) {
      debugPrint('UserProfileService: Error getting profile: $e');
      return null;
    }
  }
  
  // Update profile
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _repository.update(collectionName, userId, updates);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('UserProfileService: Error updating profile: $e');
      return false;
    }
  }
  
  // Accept privacy policy
  Future<bool> acceptPrivacyPolicy(String userId, String policyVersion) async {
    return updateUserProfile(userId, {
      'acceptedPrivacyPolicy': true,
      'policyVersion': policyVersion,
      'consentDate': DateTime.now(),
    });
  }
  
  // Mark survey complete
  Future<bool> markSurveyComplete(String userId, String surveyVersion) async {
    return updateUserProfile(userId, {
      'surveyCompleted': true,
      'surveyVersion': surveyVersion,
      'surveyCompletedAt': DateTime.now(),
    });
  }
  
  // Enable 2FA
  Future<bool> enable2FA(String userId) async {
    return updateUserProfile(userId, {
      'twoFactorEnabled': true,
      'twoFactorEnabledAt': DateTime.now(),
    });
  }
}
```

---

### Step 2: Update Cloud Functions (30 minutes)

#### 2.1 Update roles.js

**File:** `firebase-project/functions/auth/roles.js`

```javascript
const UserRole = Object.freeze({
  admin: {name: "admin", priority: 0},
  researcher: {name: "researcher", priority: 3},
  parent: {name: "parent", priority: 5},
});

const UserStatus = Object.freeze({
  active: "active",
  demo: "demo",
  suspended: "suspended",
});

function getRoleFromToken(token) {
  if (token.admin === true) return UserRole.admin;
  if (token.researcher === true) return UserRole.researcher;
  return UserRole.parent;
}

function getStatusFromToken(token) {
  if (token.demo === true) return UserStatus.demo;
  if (token.suspended === true) return UserStatus.suspended;
  return UserStatus.active;
}

module.exports = {
  UserRole,
  UserStatus,
  getRoleFromToken,
  getStatusFromToken,
};
```

#### 2.2 Update index.js onCreate function

```javascript
exports.addDefaultClaim = auth.user().onCreate(async (user) => {
  try {
    // Set default role to parent
    await getAuth().setCustomUserClaims(user.uid, {
      parent: true,
      // We'll migrate to {role: "parent"} in Phase 3
    });
    
    // Create UserProfile document
    await db.collection('UserProfile').doc(user.uid).set({
      role: 'parent',
      status: 'active',
      email: user.email,
      emailVerified: user.emailVerified,
      acceptedPrivacyPolicy: false,
      surveyCompleted: false,
      twoFactorEnabled: false,
      childIDs: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    logger.log(`UserProfile created for ${user.uid}`);
  } catch (error) {
    logger.error(`Error setting up new user: ${error}`);
  }
});
```

---

### Step 3: Update Firestore Rules (1 hour)

**File:** `firebase-project/firestore.rules`

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper Functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function getUserProfile() {
      return get(/databases/$(database)/documents/UserProfile/$(request.auth.uid));
    }
    
    function getUserRole() {
      return getUserProfile().data.role;
    }
    
    function getUserStatus() {
      return getUserProfile().data.status;
    }
    
    function isRole(role) {
      return getUserRole() == role;
    }
    
    function isStatus(status) {
      return getUserStatus() == status;
    }
    
    function isActive() {
      return isStatus('active');
    }
    
    function isDemo() {
      return isStatus('demo');
    }
    
    function isAdmin() {
      return isRole('admin');
    }
    
    function isResearcher() {
      return isRole('researcher') || isAdmin();
    }
    
    function isParent() {
      return isRole('parent');
    }
    
    // UserProfile Collection
    match /UserProfile/{userId} {
      // Users can read their own profile
      allow read: if isSignedIn() && request.auth.uid == userId;
      
      // Admins can read any profile
      allow read: if isSignedIn() && isAdmin();
      
      // Users can create their own profile (during registration)
      allow create: if isSignedIn() && 
                       request.auth.uid == userId &&
                       request.resource.data.role == 'parent'; // Default role
      
      // Users can update their own profile (but not role or status)
      allow update: if isSignedIn() && 
                       request.auth.uid == userId &&
                       request.resource.data.role == resource.data.role &&
                       request.resource.data.status == resource.data.status;
      
      // Admins can update any profile
      allow update: if isSignedIn() && isAdmin();
    }
    
    // Global Word Bank
    match /Word/{word} {
      allow read, create, update: if isSignedIn();
    }
    
    // Child Documents
    match /Child/{childId} {
      function userOwnsChild() {
        let profile = getUserProfile();
        return request.auth.uid in resource.data.parentIDs &&
               childId in profile.data.childIDs;
      }
      
      function userOwnsRequestedChild() {
        let profile = getUserProfile();
        return request.auth.uid in request.resource.data.parentIDs &&
               childId in profile.data.childIDs;
      }
      
      // Parents can read/update their own children
      allow read, update: if isSignedIn() && isActive() && userOwnsChild();
      
      // Researchers can read all children (active users only)
      allow read: if isSignedIn() && isActive() && isResearcher();
      
      // Parents can create children (must complete survey first)
      allow create: if isSignedIn() && 
                       isActive() && 
                       isParent() &&
                       getUserProfile().data.surveyCompleted == true &&
                       userOwnsRequestedChild();
      
      // No deletes
      allow delete: if false;
      
      // WordTracker subcollection
      match /WordTracker/{wordId} {
        function parentOwnsChild() {
          let childDoc = get(/databases/$(database)/documents/Child/$(childId));
          return request.auth.uid in childDoc.data.parentIDs;
        }
        
        // Parents can manage their children's word trackers
        allow read, write, create, update: if isSignedIn() && 
                                              isActive() && 
                                              parentOwnsChild();
        
        // Researchers can read
        allow read: if isSignedIn() && isActive() && isResearcher();
        
        // No deletes
        allow delete: if false;
      }
    }
    
    // Demo Collections (isolated from prod)
    match /demo_Child/{childId} {
      // Only demo users can access
      allow read, write: if isSignedIn() && isDemo();
      
      match /WordTracker/{wordId} {
        allow read, write: if isSignedIn() && isDemo();
      }
    }
    
    // Admin-only: full access to demo collections
    match /demo_{collection}/{document=**} {
      allow read, write: if isSignedIn() && isAdmin();
    }
    
    // Legacy collections (read-only for migration)
    match /Parent/{parentId} {
      allow read: if isSignedIn();
      allow write: if false; // No more writes to old collection
    }
    
    match /Researcher/{researcherId} {
      allow read: if isSignedIn();
      allow write: if false; // No more writes to old collection
    }
    
    match /User/{userId} {
      allow read: if isSignedIn();
      allow write: if false; // No more writes to old collection
    }
  }
}
```

---

### Step 4: Migration Script (2-3 hours)

#### 4.1 Create Migration Cloud Function

**File:** `firebase-project/functions/migration.js`

```javascript
const admin = require("firebase-admin");
const {logger} = require("firebase-functions");
const https = require("firebase-functions/v2/https");

const db = admin.firestore();

/**
 * Migrates users from old Parent/Researcher/User collections to new UserProfile
 * Call manually: POST to function URL with {dryRun: true/false}
 */
exports.migrateToUserProfile = https.onCall(async (req, context) => {
  // Require admin authentication
  if (!context.auth || !context.auth.token.admin) {
    throw new https.HttpsError('permission-denied', 'Admin access required');
  }
  
  const dryRun = req.data.dryRun !== false; // Default to dry run
  const results = {
    migrated: 0,
    skipped: 0,
    errors: [],
  };
  
  try {
    // Get all Parent documents
    const parentSnapshot = await db.collection('Parent').get();
    
    for (const parentDoc of parentSnapshot.docs) {
      const parentId = parentDoc.id;
      const parentData = parentDoc.data();
      
      // Check if already migrated
      const profileExists = await db.collection('UserProfile').doc(parentId).get();
      if (profileExists.exists) {
        results.skipped++;
        continue;
      }
      
      // Create UserProfile from Parent data
      const userProfile = {
        role: 'parent',
        status: 'active',
        email: null, // Will get from auth
        name: null,
        emailVerified: false,
        twoFactorEnabled: false,
        acceptedPrivacyPolicy: parentData.acceptedPrivacyPolicy || false,
        policyVersion: parentData.policyVersion || null,
        consentDate: parentData.consentDate || null,
        surveyCompleted: parentData.preStudySurveyComplete || false,
        surveyVersion: parentData.preStudySurveyComplete ? 'legacy' : null,
        childIDs: parentData.childIDs || [],
        preferredLanguage: parentData.language || 'en',
        migratedFrom: 'Parent',
        migratedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      // Get email from Firebase Auth
      try {
        const userRecord = await admin.auth().getUser(parentId);
        userProfile.email = userRecord.email;
        userProfile.name = userRecord.displayName;
        userProfile.emailVerified = userRecord.emailVerified;
      } catch (authError) {
        logger.warn(`Could not get auth data for ${parentId}: ${authError}`);
      }
      
      if (!dryRun) {
        await db.collection('UserProfile').doc(parentId).set(userProfile);
      }
      
      results.migrated++;
      logger.info(`${dryRun ? '[DRY RUN] ' : ''}Migrated Parent ${parentId}`);
    }
    
    // Get all Researcher documents
    const researcherSnapshot = await db.collection('Researcher').get();
    
    for (const researcherDoc of researcherSnapshot.docs) {
      const researcherId = researcherDoc.id;
      const researcherData = researcherDoc.data();
      
      // Check if already migrated
      const profileExists = await db.collection('UserProfile').doc(researcherId).get();
      if (profileExists.exists) {
        results.skipped++;
        continue;
      }
      
      const userProfile = {
        role: 'researcher',
        status: 'active',
        email: researcherData.email || null,
        name: researcherData.name || null,
        phoneNumber: researcherData.phoneNumber || null,
        institution: researcherData.institution || null,
        emailVerified: false,
        twoFactorEnabled: false,
        acceptedPrivacyPolicy: researcherData.acceptedPrivacyPolicy || false,
        policyVersion: researcherData.policyVersion || null,
        consentDate: researcherData.consentDate || null,
        surveyCompleted: true, // Researchers don't need survey
        childIDs: [],
        migratedFrom: 'Researcher',
        migratedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      if (!dryRun) {
        await db.collection('UserProfile').doc(researcherId).set(userProfile);
      }
      
      results.migrated++;
      logger.info(`${dryRun ? '[DRY RUN] ' : ''}Migrated Researcher ${researcherId}`);
    }
    
    return {
      success: true,
      dryRun: dryRun,
      ...results,
    };
    
  } catch (error) {
    logger.error('Migration error:', error);
    throw new https.HttpsError('internal', `Migration failed: ${error}`);
  }
});
```

#### 4.2 Run Migration

```bash
# Test first (dry run)
firebase deploy --only functions:migrateToUserProfile

# Call the function via Firebase Console or:
curl -X POST \
  https://your-region-your-project.cloudfunctions.net/migrateToUserProfile \
  -H 'Content-Type: application/json' \
  -d '{"data": {"dryRun": true}}'

# If looks good, run for real
curl -X POST \
  https://your-region-your-project.cloudfunctions.net/migrateToUserProfile \
  -H 'Content-Type: application/json' \
  -d '{"data": {"dryRun": false}}'
```

---

### Step 5: Update Flutter Code (3-4 hours)

#### 5.1 Update UserModelService

Replace the complex `_synchronizeUser` logic with simpler UserProfile-based code:

```dart
class UserModelService extends ChangeNotifier {
  UserProfile? _userProfile;
  final AuthenticationService _authenticationService;
  final UserProfileService _userProfileService;
  IDocumentListener? _listener;
  
  // Simplified synchronization
  Future<void> _synchronizeUser() async {
    if (!_authenticationService.isAuthenticated) {
      _userProfile = null;
      notifyListeners();
      return;
    }
    
    final userId = _authenticationService.userId!;
    
    // Try to get existing profile
    UserProfile? profile = await _userProfileService.getUserProfile(userId);
    
    // If doesn't exist, create it
    if (profile == null) {
      profile = UserProfile(
        id: userId,
        role: UserRole.parent, // Default
        email: _authenticationService.userEmail,
        name: _authenticationService.userName,
      );
      
      await _userProfileService.createUserProfile(profile);
    }
    
    // Set up listener
    _setupListener(userId);
    _userProfile = profile;
    notifyListeners();
  }
  
  UserProfile? get userProfile => _userProfile;
  UserRole? get userRole => _userProfile?.role;
  bool get isAuthenticated => _userProfile != null;
  bool get requiresSurvey => _userProfile?.requiresSurvey ?? false;
  bool get requires2FA => _userProfile?.requires2FA ?? false;
}
```

#### 5.2 Update AuthGate

```dart
// Simplified auth gate checks
if (!snapshot.hasData) {
  return buildSignInScreen(...);
}

if (userModelService.userProfile == null) {
  return LoadingScreen();
}

final profile = userModelService.userProfile!;

// Check privacy policy
if (!profile.acceptedPrivacyPolicy) {
  // Show privacy dialog (will be shown automatically by listener)
  return LoadingScreen();
}

// Check survey (parents only)
if (profile.requiresSurvey) {
  return RequiredSurveyPage();
}

// Check 2FA (researchers/admins only)
if (profile.requires2FA && !profile.twoFactorEnabled) {
  return Setup2FAPage();
}

// All checks passed
return profile.isParent ? HomePage() : ResearcherHomePage();
```

---

### Step 6: Delete Old Code (30 minutes)

Once migration is complete and tested:

```bash
# Delete old model files
rm lib/data/models/parent.dart
rm lib/data/models/researcher.dart
rm lib/data/models/i_user_model.dart

# Delete old service files
rm lib/data/services/parent_data_service.dart
rm lib/data/services/researcher_data_service.dart
rm lib/data/services/general_user_service.dart

# Delete old util files
rm lib/util/user_roles.dart  # Replaced by UserProfile enum
rm lib/util/user_type.dart
rm lib/util/user_role_and_type_mapper.dart
rm lib/util/user_type_collection_mapper.dart

# Update imports across codebase
# (Use IDE refactoring tools)
```

---

## Phase 2: Fix Remaining Issues (Priority: MEDIUM)

### Issue 1: Add Retry Logic for User Creation

**File:** `baby_words_tracker/lib/data/services/user_profile_service.dart`

```dart
Future<UserProfile?> createUserProfileWithRetry(
  UserProfile profile, {
  int maxRetries = 3,
  Duration retryDelay = const Duration(seconds: 2),
}) async {
  int attempts = 0;
  
  while (attempts < maxRetries) {
    try {
      return await createUserProfile(profile);
    } catch (e) {
      attempts++;
      debugPrint('UserProfileService: Create attempt $attempts failed: $e');
      
      if (attempts < maxRetries) {
        await Future.delayed(retryDelay);
      } else {
        throw Exception('Failed to create user profile after $maxRetries attempts');
      }
    }
  }
  
  return null;
}
```

### Issue 2: Add Error UI for Auth Failures

**File:** `baby_words_tracker/lib/pages/auth_gate.dart`

```dart
// Wrap build method with error handling
return StreamBuilder<User?>(
  stream: Provider.of<FirebaseAuth>(context).authStateChanges(),
  builder: (context, snapshot) {
    try {
      // ... existing logic
    } catch (error, stackTrace) {
      debugPrint('AuthGate error: $error\n$stackTrace');
      
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red),
                SizedBox(height: 24),
                Text(
                  'Authentication Error',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 12),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    Provider.of<AuthenticationService>(context, listen: false)
                        .signOut();
                  },
                  icon: Icon(Icons.logout),
                  label: Text('Sign Out and Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  },
);
```

### Issue 3: Add Logging and Monitoring

**File:** `baby_words_tracker/lib/util/auth_logger.dart`

```dart
import 'package:flutter/foundation.dart';

class AuthLogger {
  static const String _prefix = '[AUTH]';
  
  static void logUserCreation(String userId, UserRole role) {
    debugPrint('$_prefix User created: $userId (role: ${role.name})');
    // TODO: Send to analytics/monitoring service
  }
  
  static void logAuthError(String operation, dynamic error, StackTrace? stack) {
    debugPrint('$_prefix Error in $operation: $error');
    if (stack != null) {
      debugPrint('$_prefix Stack trace: $stack');
    }
    // TODO: Send to error tracking service (Sentry, Crashlytics, etc.)
  }
  
  static void logPrivacyPolicyAccepted(String userId) {
    debugPrint('$_prefix Privacy policy accepted: $userId');
    // TODO: Send to analytics
  }
  
  static void logSurveyCompleted(String userId) {
    debugPrint('$_prefix Survey completed: $userId');
    // TODO: Send to analytics
  }
}
```

---

## Phase 3: Testing Strategy

### Unit Tests

```dart
// test/models/user_profile_test.dart
void main() {
  group('UserProfile', () {
    test('default parent profile is created correctly', () {
      final profile = UserProfile(
        id: 'test123',
        role: UserRole.parent,
      );
      
      expect(profile.isParent, true);
      expect(profile.requiresSurvey, true);
      expect(profile.requires2FA, false);
    });
    
    test('researcher requires 2FA', () {
      final profile = UserProfile(
        id: 'test123',
        role: UserRole.researcher,
      );
      
      expect(profile.requires2FA, true);
    });
  });
}
```

### Integration Tests

```dart
// test/integration/auth_flow_test.dart
void main() {
  testWidgets('Full registration flow works', (tester) async {
    // 1. Start at sign-in screen
    // 2. Click register
    // 3. Fill in email/password
    // 4. Submit
    // 5. Verify loading appears
    // 6. Verify privacy dialog shows
    // 7. Accept privacy
    // 8. Verify navigation to home page
  });
}
```

---

## 📊 Estimated Timeline

| Phase | Task | Time | Dependencies |
|-------|------|------|--------------|
| 1.1 | Create UserProfile model | 1h | None |
| 1.2 | Create UserProfileService | 1h | 1.1 |
| 2.1 | Update Cloud Functions roles | 0.5h | None |
| 2.2 | Update onCreate function | 0.5h | 1.1, 2.1 |
| 3 | Update Firestore rules | 1h | 1.1 |
| 4.1 | Create migration script | 2h | 1.1, 2.2 |
| 4.2 | Run migration | 0.5h | 4.1 |
| 5.1 | Update UserModelService | 2h | 1.2 |
| 5.2 | Update AuthGate | 1h | 5.1 |
| 5.3 | Update all imports | 1h | 5.1, 5.2 |
| 6 | Delete old code | 0.5h | 5.3 |
| 7 | Add error handling | 2h | 5.3 |
| 8 | Testing | 3h | All |
| **TOTAL** | **~16 hours** | **~2-3 days** | |

---

## ✅ Checklist

### Pre-Migration
- [ ] Review plan with team
- [ ] Backup Firestore database
- [ ] Test in emulator environment
- [ ] Create rollback plan

### Phase 1: Models & Services
- [ ] Create UserProfile model
- [ ] Create UserProfileService
- [ ] Add unit tests for models
- [ ] Update Cloud Functions
- [ ] Deploy Cloud Functions to test environment

### Phase 2: Migration
- [ ] Create migration script
- [ ] Test migration in emulator (dry run)
- [ ] Run migration in production (dry run)
- [ ] Verify migration results
- [ ] Run migration for real
- [ ] Verify all users migrated

### Phase 3: Flutter Updates
- [ ] Update UserModelService
- [ ] Update AuthGate
- [ ] Update all imports across codebase
- [ ] Test registration flow
- [ ] Test sign-in flow
- [ ] Test privacy policy flow

### Phase 4: Cleanup
- [ ] Delete old model files
- [ ] Delete old service files
- [ ] Update documentation
- [ ] Deploy to production
- [ ] Monitor for errors

### Phase 5: Improvements
- [ ] Add retry logic
- [ ] Add error UI
- [ ] Add logging/monitoring
- [ ] Write integration tests

---

## 🎯 Success Criteria

1. ✅ All users migrated to UserProfile collection
2. ✅ Old Parent/Researcher collections are read-only (no new writes)
3. ✅ Registration creates UserProfile document
4. ✅ Sign-in loads from UserProfile
5. ✅ Privacy policy works with new system
6. ✅ All tests pass
7. ✅ No production errors for 24 hours after deployment

---

## 🔄 Rollback Plan

If something goes wrong:

1. **Revert Cloud Functions:** Deploy previous version
   ```bash
   firebase deploy --only functions --version previous
   ```

2. **Revert Firestore Rules:** Restore from backup
   ```bash
   firebase deploy --only firestore:rules --version previous
   ```

3. **Revert Flutter Code:** Git revert
   ```bash
   git revert HEAD
   ```

4. **Keep Data:** UserProfile collection can stay (won't interfere with old system)

---

## 📝 Notes

- Migration is **non-destructive** - old collections remain as read-only backup
- UserProfile is **additive** - doesn't delete existing data
- Can run in parallel with old system during testing phase
- Old collections can be deleted after 30-day verification period

---

**Ready to implement? Let me know which phase you'd like to start with!**


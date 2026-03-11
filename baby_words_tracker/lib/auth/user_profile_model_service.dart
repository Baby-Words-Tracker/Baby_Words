import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/data/listeners/i_document_listener.dart';
import 'package:baby_words_tracker/data/models/user_profile.dart';
import 'package:baby_words_tracker/data/services/user_profile_service.dart';
import 'package:baby_words_tracker/util/safe_synchronizer.dart';
import 'package:flutter/material.dart';

/// Manages user profile data and synchronization with authentication state
/// Replaces the old UserModelService with cleaner UserProfile-based logic
class UserProfileModelService extends ChangeNotifier {
  late final SafeSynchronizer _synchronizer;

  UserProfile? _userProfile;
  final AuthenticationService _authenticationService;
  final UserProfileService _userProfileService;

  IDocumentListener? _listener;

  int _syncCounter = 0;
  int _notifyCount = 0;

  UserProfileModelService({
    required AuthenticationService authenticationService,
    required UserProfileService userProfileService,
  })  : _authenticationService = authenticationService,
        _userProfileService = userProfileService {
    _synchronizer = SafeSynchronizer(_synchronizeUser);

    _authenticationService.addListener(() {
      debugPrint("UserProfileModelService: Auth change detected, triggering resync");
      _synchronizer.safeSynchronize().catchError((e) {
        debugPrint("UserProfileModelService: Error during sync: $e\n${e.stackTrace}");
      });
    });
  }

  /// Synchronize user profile with authentication state
  Future<void> _synchronizeUser() async {
    final syncId = ++_syncCounter;
    debugPrint("UserProfileModelService [$syncId]: Starting synchronization");

    try {
      // Not authenticated - clear profile
      if (!_authenticationService.isAuthenticated ||
          _authenticationService.userId == null) {
        _unauthenticateUser();
        debugPrint("UserProfileModelService [$syncId]: User not authenticated");
        return;
      }

      final userId = _authenticationService.userId!;
      
      // Check if user is demo (from custom claims)
      final customClaims = _authenticationService.customClaims ?? {};
      final isDemo = customClaims['demo'] == true;

      // Try to get existing profile
      debugPrint("UserProfileModelService [$syncId]: Fetching profile for $userId");
      UserProfile? profile = await _userProfileService.getUserProfile(
        userId,
        isDemo: isDemo,
      );
      debugPrint("UserProfileModelService [$syncId]: Profile fetched: ${profile != null}");

      // If profile doesn't exist, create it
      if (profile == null) {
        debugPrint("UserProfileModelService [$syncId]: Creating new UserProfile for $userId");
        
        final displayName = _authenticationService.userName;
        final parsedName = displayName != null && displayName.isNotEmpty
            ? _parseDisplayName(displayName)
            : {'firstName': null, 'lastName': null};

        profile = UserProfile(
          id: userId,
          role: UserRole.parent, // Default role
          status: isDemo ? UserStatus.demo : UserStatus.active,
          email: _authenticationService.userEmail,
          name: displayName,
          firstName: parsedName['firstName'],
          lastName: parsedName['lastName'],
        );

        // Create with retry logic
        profile = await _userProfileService.createUserProfile(profile);
        
        if (profile == null) {
          throw Exception('Failed to create user profile');
        }
      }

      debugPrint("UserProfileModelService [$syncId]: About to setup listener, current listener: ${_listener != null}");
      // Set up or refresh real-time listener FIRST
      if (_listener == null) {
        _setupListener(userId, isDemo: isDemo);
      }
      
      debugPrint("UserProfileModelService [$syncId]: Setting profile and notifying");
      // Set profile and notify (this ensures isAuthenticated returns true)
      // Mirror latest Firebase Auth displayName into UserProfile name fields if stale
      final latestName = _authenticationService.userName;
      if (latestName != null && latestName.isNotEmpty) {
        final parsedName = _parseDisplayName(latestName);
        final Map<String, dynamic> updates = {};

        if (profile.name != latestName) {
          updates['name'] = latestName;
        }
        if ((profile.firstName == null || profile.firstName!.isEmpty) &&
            parsedName['firstName'] != null &&
            parsedName['firstName']!.isNotEmpty) {
          updates['firstName'] = parsedName['firstName'];
        }
        if ((profile.lastName == null || profile.lastName!.isEmpty) &&
            parsedName['lastName'] != null &&
            parsedName['lastName']!.isNotEmpty) {
          updates['lastName'] = parsedName['lastName'];
        }

        if (updates.isNotEmpty) {
          try {
            await _userProfileService.updateUserProfile(
              profile.id,
              updates,
              isDemo: isDemo,
            );
            profile = profile.copyWith(
              name: updates.containsKey('name')
                  ? updates['name'] as String
                  : profile.name,
              firstName: updates.containsKey('firstName')
                  ? updates['firstName'] as String
                  : profile.firstName,
              lastName: updates.containsKey('lastName')
                  ? updates['lastName'] as String
                  : profile.lastName,
            );
          } catch (_) {
            // Best-effort; don't block auth flow on name sync failures
          }
        }
      }

      var currentProfile = profile!;

      _userProfile = currentProfile;
      
      final roleName = _userProfile?.role.name ?? 'unknown';
      final statusName = _userProfile?.status.name ?? 'unknown';
      debugPrint("UserProfileModelService [$syncId]: Sync complete - $roleName ($statusName)");
      
      // ALWAYS notify at the end to ensure UI updates
      debugPrint("UserProfileModelService [$syncId]: notifyListeners() #${++_notifyCount} - sync complete");
      notifyListeners();
    } catch (e, stack) {
      debugPrint("UserProfileModelService [$syncId]: Sync failed: $e\n$stack");
      rethrow; // Let error bubble up for UI to handle
    }
  }

  /// Set up real-time listener for profile updates
  void _setupListener(String userId, {bool isDemo = false}) {
    debugPrint("UserProfileModelService: Setting up listener for $userId (demo: $isDemo)");
    
    // Dispose old listener
    _listener?.dispose();

    // Create new listener
    _listener = _userProfileService.getUserProfileListener(userId, isDemo: isDemo);
    
    // Listen for changes
    _listener!.addListener(() {
      final data = _listener!.data;
      
      if (data == null) {
        debugPrint("UserProfileModelService: Profile deleted or error, unauthenticating");
        _unauthenticateUser();
        return;
      }
      
      if (data is UserProfile) {
        // Update profile from listener
        _userProfile = data;
        debugPrint("UserProfileModelService: Profile updated from listener");
        debugPrint("UserProfileModelService: notifyListeners() #${++_notifyCount} - listener update");
        notifyListeners();
      }
    });
    
    // Wait for first document
    _listener!.waitForFirstDocument().then((_) {
      debugPrint("UserProfileModelService: First document received");
    });
  }

  /// Clear user data and notify listeners
  void _unauthenticateUser() {
    _listener?.dispose();
    _listener = null;
    _userProfile = null;
    debugPrint("UserProfileModelService: User unauthenticated");
    debugPrint("UserProfileModelService: notifyListeners() #${++_notifyCount} - unauthenticated");
    notifyListeners();
  }

  // ==================== GETTERS ====================

  UserProfile? get userProfile => _userProfile;
  UserRole? get userRole => _userProfile?.role;
  UserStatus? get userStatus => _userProfile?.status;
  
  bool get isAuthenticated => _userProfile != null;
  bool get isParent => _userProfile?.isParent ?? false;
  bool get isResearcher => _userProfile?.isResearcher ?? false;
  bool get isAdmin => _userProfile?.isAdmin ?? false;
  bool get isDemoUser => _userProfile?.isDemoUser ?? false;
  bool get isActive => _userProfile?.isActive ?? false;
  
  bool get requiresSurvey => _userProfile?.requiresSurvey ?? false;
  bool get requires2FA => _userProfile?.requires2FA ?? false;
  
  bool get hasAcceptedPrivacyPolicy => _userProfile?.acceptedPrivacyPolicy ?? false;
  bool get hasSurveyCompleted => _userProfile?.surveyCompleted ?? false;
  bool get has2FAEnabled => _userProfile?.twoFactorEnabled ?? false;

  // ==================== ACTIONS ====================

  /// Accept privacy policy
  Future<void> acceptPrivacyPolicy({
    required String policyVersion,
    bool accepted = true,
  }) async {
    if (_userProfile == null) {
      debugPrint("UserProfileModelService: Cannot accept policy - no profile");
      return;
    }

    final success = await _userProfileService.acceptPrivacyPolicy(
      _userProfile!.id,
      policyVersion,
      isDemo: isDemoUser,
    );

    if (!success) {
      throw Exception('Failed to save privacy policy acceptance');
    }

    _userProfile = _userProfile!.copyWith(
      acceptedPrivacyPolicy: accepted,
      policyVersion: policyVersion,
      consentDate: DateTime.now(),
    );
    debugPrint(
        "UserProfileModelService: notifyListeners() #${++_notifyCount} - privacy policy accepted");
    notifyListeners();
  }

  /// Mark survey as complete
  Future<void> completeSurvey({required String surveyVersion}) async {
    if (_userProfile == null) {
      debugPrint("UserProfileModelService: Cannot complete survey - no profile");
      return;
    }

    final success = await _userProfileService.markSurveyComplete(
      _userProfile!.id,
      surveyVersion,
      isDemo: isDemoUser,
    );

    if (!success) {
      throw Exception('Failed to mark survey as complete');
    }

    _userProfile = _userProfile!.copyWith(
      surveyCompleted: true,
      surveyVersion: surveyVersion,
      surveyCompletedAt: DateTime.now(),
    );
    debugPrint(
        "UserProfileModelService: notifyListeners() #${++_notifyCount} - survey completed");
    notifyListeners();
  }

  /// Enable 2FA
  Future<void> enable2FA({String? phoneNumber}) async {
    if (_userProfile == null) {
      debugPrint("UserProfileModelService: Cannot enable 2FA - no profile");
      return;
    }

    await _userProfileService.enable2FA(
      _userProfile!.id,
      phoneNumber: phoneNumber,
      isDemo: isDemoUser,
    );
  }

  /// Record that the user has completed email verification
  Future<void> markEmailVerified() async {
    if (_userProfile == null) {
      debugPrint("UserProfileModelService: Cannot mark email verified - no profile");
      return;
    }

    if (_userProfile!.emailVerified) {
      debugPrint("UserProfileModelService: Email already marked as verified");
      return;
    }

    final success = await _userProfileService.updateUserProfile(
      _userProfile!.id,
      {'emailVerified': true},
      isDemo: isDemoUser,
    );

    if (success) {
      _userProfile = _userProfile!.copyWith(emailVerified: true);
      debugPrint("UserProfileModelService: notifyListeners() #${++_notifyCount} - email verified");
      notifyListeners();
    } else {
      debugPrint("UserProfileModelService: Failed to update email verified flag");
    }
  }

  /// Check if user can access given platform
  bool canAccessPlatform(String platform) {
    return _userProfile?.canAccessPlatform(platform) ?? false;
  }

  Map<String, String?> _parseDisplayName(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return {'firstName': null, 'lastName': null};
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return {'firstName': parts.first, 'lastName': null};
    }

    final first = parts.first;
    final last = parts.sublist(1).join(' ');
    return {'firstName': first, 'lastName': last};
  }

  /// Force refresh the user profile from the database
  Future<void> refreshUserProfile() async {
    debugPrint("UserProfileModelService: Force refreshing user profile");
    await _synchronizer.safeSynchronize();
  }

  @override
  void dispose() {
    _listener?.dispose();
    super.dispose();
  }
}

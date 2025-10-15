import 'package:baby_words_tracker/data/models/user_profile.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:baby_words_tracker/data/repositories/i_firestore_repository.dart';
import 'package:baby_words_tracker/data/listeners/i_document_listener.dart';
import 'package:baby_words_tracker/data/listeners/firestore_document_listener.dart';
import 'package:flutter/foundation.dart';

class UserProfileService extends ChangeNotifier {
  final IFirestoreRepository _repository;
  
  UserProfileService({IFirestoreRepository? repository})
      : _repository = repository ?? FirestoreRepository();
  
  /// Create new user profile with retry logic
  Future<UserProfile?> createUserProfile(
    UserProfile profile, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        await _repository.createWithId(
          profile.effectiveCollectionName,
          profile.id,
          profile.toMap(),
        );
        debugPrint('UserProfileService: Created profile for ${profile.id} (${profile.role.name})');
        notifyListeners();
        return profile;
      } catch (e) {
        attempts++;
        debugPrint('UserProfileService: Create attempt $attempts failed: $e');
        
        if (attempts < maxRetries) {
          await Future.delayed(retryDelay);
        } else {
          debugPrint('UserProfileService: Failed to create profile after $maxRetries attempts');
          throw Exception('Failed to create user profile after $maxRetries attempts: $e');
        }
      }
    }
    
    return null;
  }
  
  /// Get user profile
  Future<UserProfile?> getUserProfile(String userId, {bool isDemo = false}) async {
    try {
      final collectionName = isDemo ? 'demo_${UserProfile.collectionName}' : UserProfile.collectionName;
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
  
  /// Get user profile listener for real-time updates
  IDocumentListener getUserProfileListener(String userId, {bool isDemo = false}) {
    final collectionName = isDemo ? 'demo_${UserProfile.collectionName}' : UserProfile.collectionName;
    final path = '$collectionName/$userId';
    
    // Must use Firestore Repository for listener (cast if needed)
    FirestoreRepository fireRepo;
    if (_repository is FirestoreRepository) {
      fireRepo = _repository;
    } else {
      fireRepo = FirestoreRepository();
    }
    
    return FirestoreDocumentListener<UserProfile>(
      firestoreRepository: fireRepo,
      path: path,
      convertDataWithId: UserProfile.fromDataWithId,
    );
  }
  
  /// Update profile
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates, {bool isDemo = false}) async {
    try {
      final collectionName = isDemo ? 'demo_${UserProfile.collectionName}' : UserProfile.collectionName;
      await _repository.update(collectionName, userId, updates);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('UserProfileService: Error updating profile: $e');
      return false;
    }
  }
  
  /// Accept privacy policy
  Future<bool> acceptPrivacyPolicy(
    String userId, 
    String policyVersion, {
    bool isDemo = false,
  }) async {
    return updateUserProfile(
      userId,
      {
        'acceptedPrivacyPolicy': true,
        'policyVersion': policyVersion,
        'consentDate': DateTime.now(),
      },
      isDemo: isDemo,
    );
  }
  
  /// Mark survey as complete
  Future<bool> markSurveyComplete(
    String userId,
    String surveyVersion, {
    bool isDemo = false,
  }) async {
    return updateUserProfile(
      userId,
      {
        'surveyCompleted': true,
        'surveyVersion': surveyVersion,
        'surveyCompletedAt': DateTime.now(),
      },
      isDemo: isDemo,
    );
  }
  
  /// Enable 2FA
  Future<bool> enable2FA(String userId, {String? phoneNumber, bool isDemo = false}) async {
    final updates = {
      'twoFactorEnabled': true,
      'twoFactorEnabledAt': DateTime.now(),
    };
    
    // Optionally save phone number if provided
    if (phoneNumber != null) {
      updates['phoneNumber'] = phoneNumber;
    }
    
    return updateUserProfile(userId, updates, isDemo: isDemo);
  }
  
  /// Disable 2FA
  Future<bool> disable2FA(String userId, {bool isDemo = false}) async {
    return updateUserProfile(
      userId,
      {
        'twoFactorEnabled': false,
        'twoFactorEnabledAt': null,
      },
      isDemo: isDemo,
    );
  }
  
  /// Add child to parent's childIDs
  Future<bool> addChild(String userId, String childId, {bool isDemo = false}) async {
    try {
      final collectionName = isDemo ? 'demo_${UserProfile.collectionName}' : UserProfile.collectionName;
      await _repository.appendToArrayField(collectionName, userId, 'childIDs', childId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('UserProfileService: Error adding child: $e');
      return false;
    }
  }
  
  /// Remove child from parent's childIDs  
  Future<bool> removeChild(String userId, String childId, {bool isDemo = false}) async {
    try {
      final collectionName = isDemo ? 'demo_${UserProfile.collectionName}' : UserProfile.collectionName;
      // Get current profile, remove child from list, then update
      final profile = await getUserProfile(userId, isDemo: isDemo);
      if (profile == null) return false;
      
      final updatedChildIDs = profile.childIDs.where((id) => id != childId).toList();
      await _repository.update(collectionName, userId, {'childIDs': updatedChildIDs});
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('UserProfileService: Error removing child: $e');
      return false;
    }
  }
  
  /// Check if user exists
  Future<bool> userExists(String userId, {bool isDemo = false}) async {
    final profile = await getUserProfile(userId, isDemo: isDemo);
    return profile != null;
  }
  
  /// Get all user profiles (admin only)
  /// Note: Returns empty list for now - can be implemented later with proper pagination
  Future<List<UserProfile>> getAllProfiles({bool isDemo = false}) async {
    // TODO: Implement when needed for admin dashboard
    // Will need proper pagination for large user bases
    debugPrint('UserProfileService: getAllProfiles not yet implemented');
    return [];
  }
}


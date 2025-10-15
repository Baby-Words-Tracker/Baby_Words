import 'package:baby_words_tracker/data/models/user_profile.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole', () {
    test('has correct priority values', () {
      expect(UserRole.admin.priority, 0);
      expect(UserRole.researcher.priority, 3);
      expect(UserRole.parent.priority, 5);
    });

    test('canAccessData works correctly', () {
      expect(UserRole.admin.canAccessData(UserRole.parent), true);
      expect(UserRole.admin.canAccessData(UserRole.researcher), true);
      expect(UserRole.researcher.canAccessData(UserRole.parent), true);
      expect(UserRole.parent.canAccessData(UserRole.researcher), false);
      expect(UserRole.parent.canAccessData(UserRole.admin), false);
    });

    test('platform restrictions are correct', () {
      expect(UserRole.admin.allowedPlatforms, contains('web'));
      expect(UserRole.admin.allowedPlatforms, contains('mobile'));
      expect(UserRole.researcher.allowedPlatforms, equals(['web']));
      expect(UserRole.parent.allowedPlatforms, equals(['mobile']));
    });

    test('platform requirement flags work', () {
      expect(UserRole.admin.requiresWebPlatform, true);
      expect(UserRole.researcher.requiresWebPlatform, true);
      expect(UserRole.parent.requiresWebPlatform, false);
      expect(UserRole.parent.requiresMobilePlatform, true);
    });
  });

  group('UserProfile', () {
    test('default parent profile is created correctly', () {
      final profile = UserProfile(
        id: 'test123',
        role: UserRole.parent,
        email: 'parent@test.com',
      );

      expect(profile.isParent, true);
      expect(profile.isResearcher, false);
      expect(profile.isAdmin, false);
      expect(profile.requiresSurvey, true); // Parent without survey
      expect(profile.requires2FA, true); // 2FA required for ALL users
      expect(profile.isActive, true);
      expect(profile.isDemoUser, false);
    });

    test('all users require 2FA by default', () {
      final parentProfile = UserProfile(
        id: 'parent123',
        role: UserRole.parent,
        email: 'parent@test.com',
      );
      
      final researcherProfile = UserProfile(
        id: 'researcher123',
        role: UserRole.researcher,
        email: 'researcher@test.com',
      );
      
      final adminProfile = UserProfile(
        id: 'admin123',
        role: UserRole.admin,
        email: 'admin@test.com',
      );

      // All users require 2FA when twoFactorEnabled = false (default)
      expect(parentProfile.requires2FA, true);
      expect(researcherProfile.requires2FA, true);
      expect(adminProfile.requires2FA, true);
    });
    
    test('2FA requirement removed when enabled', () {
      final profile = UserProfile(
        id: 'test123',
        role: UserRole.parent,
        twoFactorEnabled: true,
      );

      expect(profile.requires2FA, false); // No longer required once enabled
      expect(profile.has2FAEnabled, true);
    });

    test('admin can access both platforms', () {
      final profile = UserProfile(
        id: 'test123',
        role: UserRole.admin,
      );

      expect(profile.canAccessPlatform('web'), true);
      expect(profile.canAccessPlatform('mobile'), true);
    });

    test('researcher can only access web', () {
      final profile = UserProfile(
        id: 'test123',
        role: UserRole.researcher,
      );

      expect(profile.canAccessPlatform('web'), true);
      expect(profile.canAccessPlatform('mobile'), false);
    });

    test('parent can only access mobile', () {
      final profile = UserProfile(
        id: 'test123',
        role: UserRole.parent,
      );

      expect(profile.canAccessPlatform('mobile'), true);
      expect(profile.canAccessPlatform('web'), false);
    });

    test('survey completion removes requirement', () {
      final profile = UserProfile(
        id: 'test123',
        role: UserRole.parent,
        surveyCompleted: true,
        surveyVersion: 'v1.0',
      );

      expect(profile.requiresSurvey, false);
    });

    test('demo user uses demo collection', () {
      final profile = UserProfile(
        id: 'test123',
        role: UserRole.parent,
        status: UserStatus.demo,
      );

      expect(profile.isDemoUser, true);
      expect(profile.effectiveCollectionName, 'demo_UserProfile');
    });

    test('active user uses normal collection', () {
      final profile = UserProfile(
        id: 'test123',
        role: UserRole.parent,
        status: UserStatus.active,
      );

      expect(profile.isActive, true);
      expect(profile.effectiveCollectionName, 'UserProfile');
    });

    test('toMap and fromMap work correctly', () {
      final originalProfile = UserProfile(
        id: 'test123',
        role: UserRole.parent,
        status: UserStatus.active,
        email: 'test@example.com',
        name: 'Test User',
        firstName: 'Test',
        lastName: 'User',
        acceptedPrivacyPolicy: true,
        policyVersion: 'v1.0',
        surveyCompleted: true,
        surveyVersion: 'v1.0',
        childIDs: ['child1', 'child2'],
        preferredLanguage: LanguageCode.en,
      );

      final map = originalProfile.toMap();
      final reconstructedProfile = UserProfile.fromMap({...map, 'id': 'test123'});

      expect(reconstructedProfile.id, originalProfile.id);
      expect(reconstructedProfile.role, originalProfile.role);
      expect(reconstructedProfile.status, originalProfile.status);
      expect(reconstructedProfile.email, originalProfile.email);
      expect(reconstructedProfile.name, originalProfile.name);
      expect(reconstructedProfile.firstName, originalProfile.firstName);
      expect(reconstructedProfile.lastName, originalProfile.lastName);
      expect(reconstructedProfile.acceptedPrivacyPolicy, originalProfile.acceptedPrivacyPolicy);
      expect(reconstructedProfile.surveyCompleted, originalProfile.surveyCompleted);
      expect(reconstructedProfile.childIDs, originalProfile.childIDs);
    });

    test('createUpdateMap only includes provided fields', () {
      final updateMap = UserProfile.createUpdateMap(
        surveyCompleted: true,
        surveyVersion: 'v1.0',
        firstName: 'Updated',
      );

      expect(updateMap.containsKey('surveyCompleted'), true);
      expect(updateMap.containsKey('surveyVersion'), true);
       expect(updateMap['firstName'], 'Updated');
      expect(updateMap.containsKey('updatedAt'), true);
      expect(updateMap.containsKey('email'), false);
      expect(updateMap.containsKey('name'), false);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = UserProfile(
        id: 'test123',
        role: UserRole.parent,
        email: 'old@example.com',
        firstName: 'Old',
        lastName: 'Name',
      );

      final updated = original.copyWith(
        email: 'new@example.com',
        firstName: 'New',
        surveyCompleted: true,
      );

      expect(updated.id, original.id);
      expect(updated.email, 'new@example.com');
      expect(updated.firstName, 'New');
      expect(updated.surveyCompleted, true);
      expect(original.email, 'old@example.com'); // Original unchanged
      expect(original.firstName, 'Old');
    });

    test('fullName falls back appropriately', () {
      final profileWithBoth = UserProfile(
        id: '1',
        role: UserRole.parent,
        firstName: 'Test',
        lastName: 'User',
      );
      final profileWithOne = UserProfile(
        id: '2',
        role: UserRole.parent,
        firstName: 'Single',
      );
      final profileWithNone = UserProfile(
        id: '3',
        role: UserRole.parent,
        name: 'Legacy Name',
      );

      expect(profileWithBoth.fullName, 'Test User');
      expect(profileWithOne.fullName, 'Single');
      expect(profileWithNone.fullName, 'Legacy Name');
    });

    test('equality works correctly', () {
      final profile1 = UserProfile(
        id: 'test123',
        role: UserRole.parent,
        email: 'test@example.com',
      );

      final profile2 = UserProfile(
        id: 'test123',
        role: UserRole.parent,
        email: 'test@example.com',
      );

      final profile3 = UserProfile(
        id: 'different',
        role: UserRole.parent,
        email: 'test@example.com',
      );

      expect(profile1, equals(profile2));
      expect(profile1, isNot(equals(profile3)));
    });
  });
}

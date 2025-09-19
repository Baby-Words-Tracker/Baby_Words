import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:baby_words_tracker/data/services/general_user_service.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/researcher_data_service.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/util/user_type.dart';
import 'package:baby_words_tracker/util/pair.dart';
import 'package:baby_words_tracker/exceptions/action_failed_exception.dart';

import '../test_helpers/firebase_test_helpers.dart';
import '../test_helpers/mock_data.dart';
import '../test_helpers/mock_firestore_repository.dart';

void main() {
  group('GeneralUserService Tests (Basic Structure)', () {
    test('should initialize correctly with mock repository', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final parentService = ParentDataService(repository: mockRepo);
      final researcherService = ResearcherDataService(repository: mockRepo);
      
      final service = GeneralUserService(
        parentDataService: parentService,
        researcherDataService: researcherService,
        repository: mockRepo,
      );
      
      expect(service, isNotNull);
    });

    test('should have required methods', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final parentService = ParentDataService(repository: mockRepo);
      final researcherService = ResearcherDataService(repository: mockRepo);
      
      final service = GeneralUserService(
        parentDataService: parentService,
        researcherDataService: researcherService,
        repository: mockRepo,
      );
      
      expect(service.createUser, isA<Function>());
      expect(service.getUser, isA<Function>());
      expect(service.getUserListener, isA<Function>());
      expect(service.changeUserType, isA<Function>());
      expect(service.setPrivacyPolicyAccepted, isA<Function>());
    });
  });

  group('GeneralUserService with Dependency Injection', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirestoreRepository mockRepo;
    late ParentDataService parentService;
    late ResearcherDataService researcherService;
    late GeneralUserService service;

    setUp(() async {
      // Setup Firebase mocks
      FirebaseTestHelpers.setupFirebaseMocks();
      fakeFirestore = FirebaseTestHelpers.fakeFirestore;
      mockRepo = MockFirestoreRepository(fakeFirestore);
      
      // Create dependent services with the same mock repository
      parentService = ParentDataService(repository: mockRepo);
      researcherService = ResearcherDataService(repository: mockRepo);
      
      // Create the service under test
      service = GeneralUserService(
        parentDataService: parentService,
        researcherDataService: researcherService,
        repository: mockRepo,
      );
    });

    tearDown(() {
      FirebaseTestHelpers.tearDown();
    });

    group('User Creation', () {
      test('should create parent user successfully', () async {
        final result = await service.createUser(
          userType: UserType.parent,
          id: 'test-parent-123',
        );

        expect(result.second, equals(UserType.parent));
        expect(result.first, isA<Parent>());
        expect((result.first as Parent).id, equals('test-parent-123'));
      });

      test('should create researcher user successfully', () async {
        final result = await service.createUser(
          userType: UserType.researcher,
          id: 'test-researcher-123',
          email: 'researcher@test.com',
          name: 'Test Researcher',
        );

        expect(result.second, equals(UserType.researcher));
        expect(result.first, isA<Researcher>());
        expect((result.first as Researcher).id, equals('test-researcher-123'));
        expect((result.first as Researcher).email, equals('researcher@test.com'));
        expect((result.first as Researcher).name, equals('Test Researcher'));
      });

      test('should return unauthenticated for invalid user type', () async {
        final result = await service.createUser(
          userType: UserType.unauthenticated,
          id: 'test-invalid-123',
        );

        expect(result.second, equals(UserType.unauthenticated));
        expect(result.first, isNull);
      });
    });

    group('Get User', () {
      test('should get parent user with expected type', () async {
        // Create a parent first
        const parentId = 'test-parent-get-123';
        await service.createUser(
          userType: UserType.parent,
          id: parentId,
        );

        // Get the user with expected type
        final result = await service.getUser(parentId, expectedType: UserType.parent);

        expect(result.second, equals(UserType.parent));
        expect(result.first, isA<Parent>());
        expect((result.first as Parent).id, equals(parentId));
      });

      test('should get researcher user with expected type', () async {
        // Create a researcher first
        const researcherId = 'test-researcher-get-123';
        await service.createUser(
          userType: UserType.researcher,
          id: researcherId,
          email: 'test@example.com',
          name: 'Test Researcher',
        );

        // Get the user with expected type
        final result = await service.getUser(researcherId, expectedType: UserType.researcher);

        expect(result.second, equals(UserType.researcher));
        expect(result.first, isA<Researcher>());
        expect((result.first as Researcher).id, equals(researcherId));
      });

      test('should find user without expected type (simultaneous queries)', () async {
        // Create a parent first
        const parentId = 'test-parent-simultaneous-123';
        await service.createUser(
          userType: UserType.parent,
          id: parentId,
        );

        // Get the user without specifying expected type
        final result = await service.getUser(parentId);

        expect(result.second, equals(UserType.parent));
        expect(result.first, isA<Parent>());
        expect((result.first as Parent).id, equals(parentId));
      });

      test('should return unauthenticated for non-existent user', () async {
        final result = await service.getUser('non-existent-user-123');

        expect(result.second, equals(UserType.unauthenticated));
        expect(result.first, isNull);
      });

      test('should fallback to other types when expected type not found', () async {
        // Create a parent
        const userId = 'test-user-fallback-123';
        await service.createUser(
          userType: UserType.parent,
          id: userId,
        );

        // Try to get as researcher first, should fallback to parent
        final result = await service.getUser(userId, expectedType: UserType.researcher);

        expect(result.second, equals(UserType.parent));
        expect(result.first, isA<Parent>());
        expect((result.first as Parent).id, equals(userId));
      });
    });

    group('Privacy Policy', () {
      test('should set privacy policy accepted for parent', () async {
        // Create a parent first
        const parentId = 'test-parent-privacy-123';
        await service.createUser(
          userType: UserType.parent,
          id: parentId,
        );

        final result = await service.setPrivacyPolicyAccepted(parentId, true, userType: UserType.parent);

        expect(result, isTrue);
      });

      test('should set privacy policy accepted for researcher', () async {
        // Create a researcher first
        const researcherId = 'test-researcher-privacy-123';
        await service.createUser(
          userType: UserType.researcher,
          id: researcherId,
          email: 'test@example.com',
          name: 'Test Researcher',
        );

        final result = await service.setPrivacyPolicyAccepted(researcherId, true, userType: UserType.researcher);

        expect(result, isTrue);
      });

      test('should determine user type automatically when not provided', () async {
        // Create a parent first
        const parentId = 'test-parent-auto-type-123';
        await service.createUser(
          userType: UserType.parent,
          id: parentId,
        );

        // Don't specify user type, let it determine automatically
        final result = await service.setPrivacyPolicyAccepted(parentId, true);

        expect(result, isTrue);
      });

      test('should return false for non-existent user', () async {
        final result = await service.setPrivacyPolicyAccepted('non-existent-user-123', true);

        expect(result, isFalse);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle null parameters gracefully', () async {
        final result = await service.getUser('');

        expect(result.second, equals(UserType.unauthenticated));
        expect(result.first, isNull);
      });

      test('should handle simultaneous queries with both types missing', () async {
        final result = await service.getUser('completely-missing-user-123');

        expect(result.second, equals(UserType.unauthenticated));
        expect(result.first, isNull);
      });
    });
  });

  group('Integration Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirestoreRepository mockRepo;
    late ParentDataService parentService;
    late ResearcherDataService researcherService;
    late GeneralUserService service;

    setUp(() async {
      FirebaseTestHelpers.setupFirebaseMocks();
      fakeFirestore = FirebaseTestHelpers.fakeFirestore;
      mockRepo = MockFirestoreRepository(fakeFirestore);
      
      parentService = ParentDataService(repository: mockRepo);
      researcherService = ResearcherDataService(repository: mockRepo);
      
      service = GeneralUserService(
        parentDataService: parentService,
        researcherDataService: researcherService,
        repository: mockRepo,
      );
    });

    tearDown(() {
      FirebaseTestHelpers.tearDown();
    });

    test('should handle complete user workflow - create, get, update privacy', () async {
      const userId = 'test-workflow-user-123';
      
      // Step 1: Create user
      final createResult = await service.createUser(
        userType: UserType.parent,
        id: userId,
      );
      expect(createResult.second, equals(UserType.parent));
      expect(createResult.first, isA<Parent>());
      
      // Step 2: Get user
      final getResult = await service.getUser(userId);
      expect(getResult.second, equals(UserType.parent));
      expect(getResult.first, isA<Parent>());
      expect((getResult.first as Parent).id, equals(userId));
      
      // Step 3: Update privacy policy
      final privacyResult = await service.setPrivacyPolicyAccepted(userId, true);
      expect(privacyResult, isTrue);
      
      // Step 4: Verify user still exists
      final finalGetResult = await service.getUser(userId);
      expect(finalGetResult.second, equals(UserType.parent));
      expect(finalGetResult.first, isA<Parent>());
    });

    test('should handle user type preference correctly', () async {
      const userId = 'test-preference-user-123';
      
      // Create a parent
      await service.createUser(
        userType: UserType.parent,
        id: userId,
      );
      
      // Test getting with correct expected type (fast path)
      final correctTypeResult = await service.getUser(userId, expectedType: UserType.parent);
      expect(correctTypeResult.second, equals(UserType.parent));
      
      // Test getting with wrong expected type (should fallback)
      final wrongTypeResult = await service.getUser(userId, expectedType: UserType.researcher);
      expect(wrongTypeResult.second, equals(UserType.parent)); // Should still find as parent
      
      // Test getting with no expected type (simultaneous queries)
      final noTypeResult = await service.getUser(userId);
      expect(noTypeResult.second, equals(UserType.parent));
    });
  });
}

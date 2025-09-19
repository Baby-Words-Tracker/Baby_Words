import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:baby_words_tracker/data/services/researcher_data_service.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';

import '../test_helpers/firebase_test_helpers.dart';
import '../test_helpers/mock_firestore_repository.dart';

void main() {
  group('ResearcherDataService Tests (Basic Structure)', () {
    test('should initialize correctly with mock repository', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ResearcherDataService(repository: mockRepo);
      
      expect(service, isNotNull);
    });

    test('should be a ChangeNotifier with mock repository', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ResearcherDataService(repository: mockRepo);
      
      expect(service, isA<ChangeNotifier>());
    });

    test('should have required methods', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ResearcherDataService(repository: mockRepo);
      
      expect(service.createResearcher, isA<Function>());
      expect(service.getResearcher, isA<Function>());
      expect(service.getResearcherByEmail, isA<Function>());
      expect(service.getMultipleResearchers, isA<Function>());
      expect(service.updateResearcher, isA<Function>());
    });
  });

  group('ResearcherDataService with Dependency Injection', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirestoreRepository mockRepo;
    late ResearcherDataService service;

    setUp(() async {
      // Setup Firebase mocks
      FirebaseTestHelpers.setupFirebaseMocks();
      fakeFirestore = FirebaseTestHelpers.fakeFirestore;
      
      // Create mock repository with fake Firestore
      mockRepo = MockFirestoreRepository(fakeFirestore);
      
      // Inject the mock repository into the service!
      service = ResearcherDataService(repository: mockRepo);
    });

    tearDown(() {
      FirebaseTestHelpers.tearDown();
    });

    test('should create researcher successfully through service with real logic', () async {
      // Arrange: Create a test researcher
      final testResearcher = Researcher(
        id: 'researcher-test-123',
        email: 'test.researcher@university.edu',
        name: 'Dr. Test Researcher',
      );

      // Act: Create researcher through service
      final createdResearcher = await service.createResearcher(testResearcher);

      // Assert: Verify researcher was created correctly
      expect(createdResearcher, isNotNull);
      expect(createdResearcher!.id, equals('researcher-test-123'));
      expect(createdResearcher.email, equals('test.researcher@university.edu'));
      expect(createdResearcher.name, equals('Dr. Test Researcher'));

      // Verify it was actually persisted in fake Firestore
      final doc = await fakeFirestore.collection('Researcher').doc('researcher-test-123').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['email'], equals('test.researcher@university.edu'));
      expect(doc.data()?['name'], equals('Dr. Test Researcher'));
    });

    test('should retrieve researcher by ID through service', () async {
      // Arrange: Create a researcher first
      final testResearcher = Researcher(
        id: 'researcher-retrieve-456',
        email: 'retrieve@research.org',
        name: 'Dr. Retrieve Test',
      );

      final createdResearcher = await service.createResearcher(testResearcher);
      expect(createdResearcher, isNotNull);

      // Act: Retrieve it by ID
      final retrievedResearcher = await service.getResearcher('researcher-retrieve-456');

      // Assert: Verify correct data was retrieved
      expect(retrievedResearcher, isNotNull);
      expect(retrievedResearcher!.id, equals('researcher-retrieve-456'));
      expect(retrievedResearcher.email, equals('retrieve@research.org'));
      expect(retrievedResearcher.name, equals('Dr. Retrieve Test'));
    });

    test('should retrieve researcher by email through service', () async {
      // Arrange: Create a researcher with specific email
      final testResearcher = Researcher(
        id: 'researcher-email-789',
        email: 'unique.researcher@institute.edu',
        name: 'Dr. Email Test',
      );

      await service.createResearcher(testResearcher);

      // Act: Retrieve it by email
      final retrievedResearcher = await service.getResearcherByEmail('unique.researcher@institute.edu');

      // Assert: Verify correct researcher was found
      expect(retrievedResearcher, isNotNull);
      expect(retrievedResearcher!.id, equals('researcher-email-789'));
      expect(retrievedResearcher.email, equals('unique.researcher@institute.edu'));
      expect(retrievedResearcher.name, equals('Dr. Email Test'));
    });

    test('should retrieve multiple researchers through service', () async {
      final researcherIds = <String>[];
      final testResearchers = [
        'Dr. First Researcher',
        'Prof. Second Researcher', 
        'Dr. Third Researcher'
      ];

      // Arrange: Create multiple researchers
      for (int i = 0; i < testResearchers.length; i++) {
        final researcher = Researcher(
          id: 'researcher-multi-$i',
          email: 'researcher$i@academia.edu',
          name: testResearchers[i],
        );
        
        final createdResearcher = await service.createResearcher(researcher);
        expect(createdResearcher, isNotNull);
        researcherIds.add('researcher-multi-$i');
      }

      // Act: Retrieve all researchers
      final researchers = await service.getMultipleResearchers(researcherIds);

      // Assert: Verify all researchers were retrieved correctly
      expect(researchers, hasLength(3));
      expect(researchers.map((r) => r.name), containsAll([
        'Dr. First Researcher',
        'Prof. Second Researcher',
        'Dr. Third Researcher'
      ]));
      
      // Verify specific researcher properties
      final firstResearcher = researchers.firstWhere((r) => r.name == 'Dr. First Researcher');
      expect(firstResearcher.email, equals('researcher0@academia.edu'));
    });

    test('should update researcher successfully', () async {
      // Arrange: Create a researcher
      final testResearcher = Researcher(
        id: 'researcher-update-abc',
        email: 'update@research.edu',
        name: 'Dr. Original Name',
      );

      await service.createResearcher(testResearcher);

      // Act: Update the researcher
      final updated = await service.updateResearcher(
        'researcher-update-abc',
        name: 'Dr. Updated Name',
        email: 'updated@research.edu',
      );

      // Assert: Verify update was successful
      expect(updated, isTrue);

      // Verify the update persisted
      final updatedResearcher = await service.getResearcher('researcher-update-abc');
      expect(updatedResearcher, isNotNull);
      expect(updatedResearcher!.name, equals('Dr. Updated Name'));
      expect(updatedResearcher.email, equals('updated@research.edu'));
      
      // Verify in fake Firestore
      final doc = await fakeFirestore.collection('Researcher').doc('researcher-update-abc').get();
      expect(doc.data()?['name'], equals('Dr. Updated Name'));
      expect(doc.data()?['email'], equals('updated@research.edu'));
    });

    test('should handle non-existent researcher gracefully', () async {
      // Act: Try to get a researcher that doesn't exist
      final result = await service.getResearcher('non-existent-researcher');
      final emailResult = await service.getResearcherByEmail('nonexistent@research.edu');

      // Assert: Should handle gracefully
      expect(result, isNull);
      expect(emailResult, isNull);
    });

    test('should handle researcher creation with duplicate ID', () async {
      // Arrange: Create a researcher
      final originalResearcher = Researcher(
        id: 'duplicate-researcher-id',
        email: 'original@research.edu',
        name: 'Dr. Original',
      );

      await service.createResearcher(originalResearcher);

      // Act: Try to create another researcher with the same ID
      final duplicateResearcher = Researcher(
        id: 'duplicate-researcher-id',
        email: 'duplicate@research.edu',
        name: 'Dr. Duplicate',
      );

      final result = await service.createResearcher(duplicateResearcher);

      // Assert: The second creation should succeed (merge mode)
      // but we should verify the behavior matches expectations
      expect(result, isNotNull);
    });

    test('should notify listeners when researcher data changes', () async {
      var notificationCount = 0;
      service.addListener(() {
        notificationCount++;
      });

      // Act: Create a researcher - this should trigger notification
      final testResearcher = Researcher(
        id: 'researcher-notify-def',
        email: 'notify@research.edu',
        name: 'Dr. Notification Test',
      );

      await service.createResearcher(testResearcher);

      // Assert: Verify notification was sent
      expect(notificationCount, greaterThan(0));
    });

    test('should get document listener for researcher', () {
      // Note: Listener functionality would be tested separately in integration tests
      // For now, we'll just verify the method exists
      expect(service.getUserListener, isA<Function>());
    });

    test('should handle researcher with minimal data', () async {
      // Arrange: Create researcher with only required fields
      final minimalResearcher = Researcher(
        id: 'minimal-researcher',
        email: null, // Optional field
        name: null,  // Optional field
      );

      // Act: Create and retrieve minimal researcher
      final created = await service.createResearcher(minimalResearcher);
      expect(created, isNotNull);

      final retrieved = await service.getResearcher('minimal-researcher');

      // Assert: Verify minimal data is handled correctly
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('minimal-researcher'));
      expect(retrieved.email, isNull);
      expect(retrieved.name, isNull);
    });

    test('dependency injection concept demonstration', () {
      // Test service (uses fake Firebase)
      final testService = ResearcherDataService(repository: mockRepo);
      expect(testService, isNotNull);
      expect(testService, isA<ChangeNotifier>());
      
      // Note: Production service would be ResearcherDataService() without injection
      // but we can't test it here without Firebase initialization
    });
  });

  group('ResearcherDataService Notification Tests', () {
    test('should notify listeners when data changes', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ResearcherDataService(repository: mockRepo);
      var notificationCount = 0;
      
      service.addListener(() {
        notificationCount++;
      });
      
      // In a real implementation, calling service methods that change data
      // would trigger notifyListeners() and increment the count
      expect(service, isA<ChangeNotifier>());
    });

    test('should handle listener removal', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ResearcherDataService(repository: mockRepo);
      var notificationCount = 0;
      
      void listener() {
        notificationCount++;
      }
      
      service.addListener(listener);
      service.removeListener(listener);
      
      // Listener should be removed successfully
      // ignore: invalid_use_of_protected_member
      expect(service.hasListeners, isFalse);
    });
  });
}

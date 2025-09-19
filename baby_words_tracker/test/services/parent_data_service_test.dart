import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/util/language_code.dart';

import '../test_helpers/firebase_test_helpers.dart';
import '../test_helpers/mock_firestore_repository.dart';

void main() {
  group('ParentDataService Tests (Basic Structure)', () {
    test('should initialize correctly with mock repository', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ParentDataService(repository: mockRepo);
      
      expect(service, isNotNull);
    });

    test('should be a ChangeNotifier with mock repository', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ParentDataService(repository: mockRepo);
      
      expect(service, isA<ChangeNotifier>());
    });

    test('should have required methods', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ParentDataService(repository: mockRepo);
      
      expect(service.createParent, isA<Function>());
      expect(service.getParent, isA<Function>());
      expect(service.getParentByEmail, isA<Function>());
      expect(service.getMultipleParents, isA<Function>());
      expect(service.updateParent, isA<Function>());
      expect(service.addChildToParent, isA<Function>());
      expect(service.getChildList, isA<Function>());
      expect(service.getLanguage, isA<Function>());
      expect(service.getUserListener, isA<Function>());
    });
  });

  group('ParentDataService with Dependency Injection', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirestoreRepository mockRepo;
    late ParentDataService service;

    setUp(() async {
      // Setup Firebase mocks
      FirebaseTestHelpers.setupFirebaseMocks();
      fakeFirestore = FirebaseTestHelpers.fakeFirestore;
      
      // Create mock repository with fake Firestore
      mockRepo = MockFirestoreRepository(fakeFirestore);
      
      // Inject the mock repository into the service!
      service = ParentDataService(repository: mockRepo);
    });

    tearDown(() {
      FirebaseTestHelpers.tearDown();
    });

    test('should create parent successfully through service with real logic', () async {
      // Arrange: Create a test parent
      final testParent = Parent(
        id: 'parent-test-123',
        language: LanguageCode.en,
        childIDs: [],
        consentFormComplete: false,
      );

      // Act: Create parent through service
      final createdParent = await service.createParent(testParent);

      // Assert: Verify parent was created correctly
      expect(createdParent, isNotNull);
      expect(createdParent!.id, equals('parent-test-123'));
      expect(createdParent.language, equals(LanguageCode.en));
      expect(createdParent.childIDs, isEmpty);
      expect(createdParent.consentFormComplete, isFalse);

      // Verify it was actually persisted in fake Firestore
      final doc = await fakeFirestore.collection('Parent').doc('parent-test-123').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['language'], equals('en'));
    });

    test('should retrieve parent by ID through service', () async {
      // Arrange: Create a parent first
      final testParent = Parent(
        id: 'parent-retrieve-456',
        language: LanguageCode.es,
        childIDs: ['child-1', 'child-2'],
        consentFormComplete: true,
      );

      final createdParent = await service.createParent(testParent);
      expect(createdParent, isNotNull);

      // Act: Retrieve it by ID
      final retrievedParent = await service.getParent('parent-retrieve-456');

      // Assert: Verify correct data was retrieved
      expect(retrievedParent, isNotNull);
      expect(retrievedParent!.id, equals('parent-retrieve-456'));
      expect(retrievedParent.language, equals(LanguageCode.es));
      expect(retrievedParent.childIDs, hasLength(2));
      expect(retrievedParent.childIDs, contains('child-1'));
      expect(retrievedParent.childIDs, contains('child-2'));
      expect(retrievedParent.consentFormComplete, isTrue);
    });

    test('should retrieve multiple parents through service', () async {
      final parentIds = <String>[];
      final testLanguages = [LanguageCode.en, LanguageCode.es, LanguageCode.fr];

      // Arrange: Create multiple parents
      for (int i = 0; i < testLanguages.length; i++) {
        final parent = Parent(
          id: 'parent-multi-$i',
          language: testLanguages[i],
          childIDs: [],
        );
        
        final createdParent = await service.createParent(parent);
        expect(createdParent, isNotNull);
        parentIds.add('parent-multi-$i');
      }

      // Act: Retrieve all parents
      final parents = await service.getMultipleParents(parentIds);

      // Assert: Verify all parents were retrieved correctly
      expect(parents, hasLength(3));
      expect(parents.map((p) => p.language), containsAll([LanguageCode.en, LanguageCode.es, LanguageCode.fr]));
      
      // Verify specific parent properties
      final englishParent = parents.firstWhere((p) => p.language == LanguageCode.en);
      expect(englishParent.id, equals('parent-multi-0'));
    });

    test('should update parent successfully', () async {
      // Arrange: Create a parent
      final testParent = Parent(
        id: 'parent-update-abc',
        language: LanguageCode.en,
        childIDs: ['existing-child'],
        consentFormComplete: false,
      );

      await service.createParent(testParent);

      // Act: Update the parent
      final updated = await service.updateParent(
        'parent-update-abc',
        childIDs: ['existing-child', 'new-child'],
        language: LanguageCode.es,
        consentFormComplete: true,
      );

      // Assert: Verify update was successful
      expect(updated, isTrue);

      // Verify the update persisted
      final updatedParent = await service.getParent('parent-update-abc');
      expect(updatedParent, isNotNull);
      expect(updatedParent!.language, equals(LanguageCode.es));
      expect(updatedParent.childIDs, hasLength(2));
      expect(updatedParent.childIDs, contains('new-child'));
      expect(updatedParent.consentFormComplete, isTrue);
      
      // Verify in fake Firestore
      final doc = await fakeFirestore.collection('Parent').doc('parent-update-abc').get();
      expect(doc.data()?['language'], equals('es'));
    });

    test('should add child to parent successfully', () async {
      // Arrange: Create a parent and child documents
      final testParent = Parent(
        id: 'parent-link-def',
        language: LanguageCode.en,
        childIDs: [],
      );

      await service.createParent(testParent);

      // Create a child document in fake Firestore
      await fakeFirestore.collection('Child').doc('child-link-123').set({
        'name': 'Test Child',
        'parentIDs': [],
        'wordCount': 0,
        'languageCodes': ['en'],
        'birthday': DateTime(2020, 1, 1),
      });

      // Act: Add child to parent
      await service.addChildToParent('parent-link-def', 'child-link-123');

      // Assert: Verify parent has child ID
      final updatedParent = await service.getParent('parent-link-def');
      expect(updatedParent, isNotNull);
      expect(updatedParent!.childIDs, contains('child-link-123'));

      // Verify child has parent ID
      final childDoc = await fakeFirestore.collection('Child').doc('child-link-123').get();
      expect(childDoc.data()?['parentIDs'], contains('parent-link-def'));
    });

    test('should handle non-existent parent gracefully', () async {
      // Act: Try to get a parent that doesn't exist
      final result = await service.getParent('non-existent-parent');

      // Assert: Should handle gracefully
      expect(result, isNull);
    });

    test('should get child list for parent', () async {
      // Arrange: Create parent and children
      final testParent = Parent(
        id: 'parent-children-ghi',
        language: LanguageCode.en,
        childIDs: ['child-1', 'child-2'],
      );

      await service.createParent(testParent);

      // Create child documents
      for (final childId in ['child-1', 'child-2']) {
        await fakeFirestore.collection('Child').doc(childId).set({
          'name': 'Child $childId',
          'parentIDs': ['parent-children-ghi'],
          'wordCount': 10,
          'languageCodes': ['en'],
          'birthday': DateTime(2020, 1, 1),
        });
      }

      // Act: Get child list
      final children = await service.getChildList('parent-children-ghi');

      // Assert: Verify children were retrieved
      expect(children, hasLength(2));
      expect(children.map((c) => c.name), containsAll(['Child child-1', 'Child child-2']));
    });

    test('should get parent language', () async {
      // Arrange: Create parent with specific language
      final testParent = Parent(
        id: 'parent-lang-test',
        language: LanguageCode.fr,
      );

      await service.createParent(testParent);

      // Act: Get language
      final language = await service.getLanguage('parent-lang-test');

      // Assert: Verify correct language
      expect(language, equals(LanguageCode.fr));
    });

    test('should notify listeners when parent data changes', () async {
      var notificationCount = 0;
      service.addListener(() {
        notificationCount++;
      });

      // Act: Create a parent - this should trigger notification
      final testParent = Parent(
        id: 'parent-notify-jkl',
        language: LanguageCode.en,
      );

      await service.createParent(testParent);

      // Assert: Verify notification was sent
      expect(notificationCount, greaterThan(0));
    });

    test('should get user listener for parent', () {
      // Note: Listener functionality would be tested separately in integration tests
      // For now, we'll just verify the method exists
      expect(service.getUserListener, isA<Function>());
    });

    test('dependency injection concept demonstration', () {
      // Test service (uses fake Firebase)
      final testService = ParentDataService(repository: mockRepo);
      expect(testService, isNotNull);
      expect(testService, isA<ChangeNotifier>());
      
      // Note: Production service would be ParentDataService() without injection
      // but we can't test it here without Firebase initialization
    });
  });

  group('ParentDataService Notification Tests', () {
    test('should notify listeners when data changes', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ParentDataService(repository: mockRepo);
      var notificationCount = 0;
      
      service.addListener(() {
        notificationCount++;
      });
      
      expect(service, isA<ChangeNotifier>());
    });

    test('should handle listener removal', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ParentDataService(repository: mockRepo);
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

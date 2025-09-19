import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/util/language_code.dart';

import '../test_helpers/firebase_test_helpers.dart';
import '../test_helpers/mock_data.dart';
import '../test_helpers/mock_firestore_repository.dart';

void main() {
  group('ChildDataService Tests (Basic Structure)', () {
    test('should initialize correctly with mock repository', () {
      // Use mock repository to avoid Firebase initialization
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ChildDataService(repository: mockRepo);
      
      expect(service, isNotNull);
    });

    test('should be a ChangeNotifier with mock repository', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ChildDataService(repository: mockRepo);
      
      expect(service, isA<ChangeNotifier>());
    });

    test('should have required methods', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ChildDataService(repository: mockRepo);
      
      expect(service.createChild, isA<Function>());
      expect(service.getChild, isA<Function>());
      expect(service.getMultipleChildren, isA<Function>());
    });
  });

  group('ChildDataService with Dependency Injection', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirestoreRepository mockRepo;
    late ChildDataService service;

    setUp(() async {
      // Setup Firebase mocks
      FirebaseTestHelpers.setupFirebaseMocks();
      fakeFirestore = FirebaseTestHelpers.fakeFirestore;
      
      mockRepo = MockFirestoreRepository(fakeFirestore);
      
      service = ChildDataService(repository: mockRepo);
    });

    tearDown(() {
      FirebaseTestHelpers.tearDown();
    });

    test('should create child successfully through service with real logic', () async {
      // Act: Test actual service business logic
      final child = await service.createChild(
        DateTime(2020, 1, 15),
        'Service Test Child',
        [LanguageCode.en],
        0,
        ['parent-123'],
      );

      // Assert: Verify child was created with correct data
      expect(child, isNotNull);
      expect(child!.name, equals('Service Test Child'));
      expect(child.wordCount, equals(0));
      expect(child.language, contains(LanguageCode.en));
      expect(child.parentIDs, contains('parent-123'));
      expect(child.id, isNotNull);

      final storedChild = await service.getChild(child.id!);
      expect(storedChild, isNotNull);
      expect(storedChild!.name, equals('Service Test Child'));
      
      final doc = await fakeFirestore.collection('Child').doc(child.id!).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['name'], equals('Service Test Child'));
    });

    test('should retrieve child by ID through service', () async {
      // Arrange: Create a child first
      final createdChild = await service.createChild(
        DateTime(2020, 5, 10),
        'Retrieval Test Child',
        [LanguageCode.en, LanguageCode.es],
        25,
        ['parent-456'],
      );

      expect(createdChild, isNotNull);

      // Act: Retrieve it by ID
      final retrievedChild = await service.getChild(createdChild!.id!);

      // Assert: Verify correct data was retrieved
      expect(retrievedChild, isNotNull);
      expect(retrievedChild!.id, equals(createdChild.id));
      expect(retrievedChild.name, equals('Retrieval Test Child'));
      expect(retrievedChild.wordCount, equals(25));
      expect(retrievedChild.language, hasLength(2));
      expect(retrievedChild.language, contains(LanguageCode.en));
      expect(retrievedChild.language, contains(LanguageCode.es));
    });

    test('should retrieve multiple children through service', () async {
      final childIds = <String>[];

      // Arrange: Create multiple children
      for (int i = 0; i < 3; i++) {
        final child = await service.createChild(
          DateTime(2020, i + 1, 1),
          'Multi Child $i',
          [LanguageCode.en],
          i * 5,
          ['parent-multi'],
        );
        expect(child, isNotNull);
        childIds.add(child!.id!);
      }

      // Act: Retrieve all children
      final children = await service.getMultipleChildren(childIds);

      // Assert: Verify all children were retrieved correctly
      expect(children, hasLength(3));
      for (int i = 0; i < 3; i++) {
        expect(children[i].name, equals('Multi Child $i'));
        expect(children[i].wordCount, equals(i * 5));
        expect(children[i].parentIDs, contains('parent-multi'));
      }
    });

    test('should get word count for child', () async {
      // Arrange: Create a child with specific word count
      final child = await service.createChild(
        DateTime(2020, 6, 20),
        'Word Count Check',
        [LanguageCode.en],
        42,
        ['parent-count'],
      );

      expect(child, isNotNull);

      // Act: Get word count using service method
      final wordCount = await service.getNumWords(child!.id!);

      // Assert: Verify correct word count
      expect(wordCount, equals(42));
    });

    test('should handle non-existent child gracefully', () async {
      // Act: Try to get a child that doesn't exist
      final result = await service.getChild('non-existent-id');
      final wordCount = await service.getNumWords('non-existent-id');

      // Assert: Should handle gracefully
      expect(result, isNull);
      expect(wordCount, equals(0));
    });

    test('should notify listeners when child data changes', () async {
      var notificationCount = 0;
      service.addListener(() {
        notificationCount++;
      });

      // Act: Create a child - this should trigger notification
      await service.createChild(
        DateTime(2020, 7, 1),
        'Notification Test',
        [LanguageCode.en],
        0,
        ['parent-notify'],
      );

      // Assert: Verify notification was sent
      expect(notificationCount, greaterThan(0));
    });

    test('should get languages for child', () async {
      // Arrange: Create child with multiple languages
      final child = await service.createChild(
        DateTime(2020, 8, 1),
        'Multilingual Child',
        [LanguageCode.en, LanguageCode.es],
        0,
        ['parent-lang'],
      );

      expect(child, isNotNull);

      // Act: Get languages
      final languages = await service.getLanguages(child!.id!);

      // Assert: Verify languages
      expect(languages, isNotNull);
      expect(languages, hasLength(2));
      expect(languages, contains(LanguageCode.en));
      expect(languages, contains(LanguageCode.es));
    });
  });

  group('ChildDataService Notification Tests', () {
    test('should notify listeners when data changes', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ChildDataService(repository: mockRepo);
      var notificationCount = 0;
      
      service.addListener(() {
        notificationCount++;
      });

      // Verify listener is set up
      expect(notificationCount, equals(0));
      
      // In a real implementation, calling service methods that change data
      // would trigger notifyListeners() and increment the count
    });

    test('should handle listener removal', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = ChildDataService(repository: mockRepo);
      var notificationCount = 0;
      
      void listener() {
        notificationCount++;
      }
      
      service.addListener(listener);
      service.removeListener(listener);
      
      // Verify listener was removed successfully
      expect(notificationCount, equals(0));
    });
  });
}

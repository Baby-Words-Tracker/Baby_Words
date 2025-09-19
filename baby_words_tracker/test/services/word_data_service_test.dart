import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';

import '../test_helpers/firebase_test_helpers.dart';
import '../test_helpers/mock_firestore_repository.dart';

void main() {
  group('WordDataService Tests (Basic Structure)', () {
    test('should initialize correctly with mock repository', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = WordDataService(repository: mockRepo);
      
      expect(service, isNotNull);
    });

    test('should be a ChangeNotifier with mock repository', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = WordDataService(repository: mockRepo);
      
      expect(service, isA<ChangeNotifier>());
    });

    test('should have required methods', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = WordDataService(repository: mockRepo);
      
      expect(service.createWord, isA<Function>());
      expect(service.getWord, isA<Function>());
      expect(service.getMultipleWords, isA<Function>());
      expect(service.updateWord, isA<Function>());
    });
  });

  group('WordDataService with Dependency Injection (REAL TESTING!)', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirestoreRepository mockRepo;
    late WordDataService service;

    setUp(() async {
      // Setup Firebase mocks
      FirebaseTestHelpers.setupFirebaseMocks();
      fakeFirestore = FirebaseTestHelpers.fakeFirestore;
      
      // Create mock repository with fake Firestore
      mockRepo = MockFirestoreRepository(fakeFirestore);
      
      // ✅ Inject the mock repository into the service!
      service = WordDataService(repository: mockRepo);
    });

    tearDown(() {
      FirebaseTestHelpers.tearDown();
    });

    test('should create word successfully through service with real logic', () async {
      // Arrange: Create a test word
      final testWord = Word(
        word: 'hello',
        languageCodes: {LanguageCode.en},
        partOfSpeech: {LanguageCode.en: PartOfSpeech.noun},
        needsProcessing: false,
      );

      // Act: Create word through service
      final createdWord = await service.createWord(testWord);

      // Assert: Verify word was created correctly
      expect(createdWord, isNotNull);
      expect(createdWord!.word, equals('hello'));
      expect(createdWord.languageCodes, contains(LanguageCode.en));
      expect(createdWord.partOfSpeech[LanguageCode.en], equals(PartOfSpeech.noun));
      expect(createdWord.needsProcessing, isFalse);

      // ✅ Verify it was actually persisted in fake Firestore
      final doc = await fakeFirestore.collection('Word').doc('hello').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['languageCodes'], contains('en'));
    });

    test('should retrieve word by ID through service', () async {
      // Arrange: Create a word first
      final testWord = Word(
        word: 'goodbye',
        languageCodes: {LanguageCode.en, LanguageCode.es},
        partOfSpeech: {
          LanguageCode.en: PartOfSpeech.noun,
          LanguageCode.es: PartOfSpeech.noun,
        },
        needsProcessing: true,
      );

      final createdWord = await service.createWord(testWord);
      expect(createdWord, isNotNull);

      // Act: Retrieve it by ID
      final retrievedWord = await service.getWord('goodbye');

      // Assert: Verify correct data was retrieved
      expect(retrievedWord, isNotNull);
      expect(retrievedWord!.word, equals('goodbye'));
      expect(retrievedWord.languageCodes, hasLength(2));
      expect(retrievedWord.languageCodes, contains(LanguageCode.en));
      expect(retrievedWord.languageCodes, contains(LanguageCode.es));
      expect(retrievedWord.needsProcessing, isTrue);
    });

    test('should retrieve multiple words through service', () async {
      final wordIds = <String>[];
      final testWords = ['cat', 'dog', 'bird'];

      // Arrange: Create multiple words
      for (int i = 0; i < testWords.length; i++) {
        final word = Word(
          word: testWords[i],
          languageCodes: {LanguageCode.en},
          partOfSpeech: {LanguageCode.en: PartOfSpeech.noun},
          needsProcessing: i == 1, // Only 'dog' needs processing
        );
        
        final createdWord = await service.createWord(word);
        expect(createdWord, isNotNull);
        wordIds.add(testWords[i]);
      }

      // Act: Retrieve all words
      final words = await service.getMultipleWords(wordIds);

      // Assert: Verify all words were retrieved correctly
      expect(words, hasLength(3));
      expect(words.map((w) => w.word), containsAll(['cat', 'dog', 'bird']));
      
      // Verify specific word properties
      final dog = words.firstWhere((w) => w.word == 'dog');
      expect(dog.needsProcessing, isTrue);
      
      final cat = words.firstWhere((w) => w.word == 'cat');
      expect(cat.needsProcessing, isFalse);
    });

    test('should update word successfully', () async {
      // Arrange: Create a word that needs processing
      final testWord = Word(
        word: 'update_test',
        languageCodes: {LanguageCode.en},
        partOfSpeech: {LanguageCode.en: PartOfSpeech.noun},
        needsProcessing: true,
      );

      await service.createWord(testWord);

      // Act: Update the word to mark processing as complete
      final updateMap = {'needsProcessing': false};
      final updated = await service.updateWord('update_test', updateMap);

      // Assert: Verify update was successful
      expect(updated, isTrue);

      // Verify the update persisted
      final updatedWord = await service.getWord('update_test');
      expect(updatedWord, isNotNull);
      expect(updatedWord!.needsProcessing, isFalse);
      
      // Verify in fake Firestore
      final doc = await fakeFirestore.collection('Word').doc('update_test').get();
      expect(doc.data()?['needsProcessing'], isFalse);
    });

    test('should handle non-existent word gracefully', () async {
      // Act: Try to get a word that doesn't exist
      final result = await service.getWord('non-existent-word');

      // Assert: Should handle gracefully
      expect(result, isNull);
    });

    test('should handle empty update map gracefully', () async {
      // Arrange: Create a word
      final testWord = Word(
        word: 'empty_update',
        languageCodes: {LanguageCode.en},
        partOfSpeech: {LanguageCode.en: PartOfSpeech.verb},
      );

      await service.createWord(testWord);

      // Act: Try to update with empty map
      final updated = await service.updateWord('empty_update', {});

      // Assert: Should return true (no-op)
      expect(updated, isTrue);
    });

    test('should notify listeners when word data changes', () async {
      var notificationCount = 0;
      service.addListener(() {
        notificationCount++;
      });

      // Act: Create a word - this should trigger notification
      final testWord = Word(
        word: 'notification_test',
        languageCodes: {LanguageCode.en},
        partOfSpeech: {LanguageCode.en: PartOfSpeech.adjective},
      );

      await service.createWord(testWord);

      // Assert: Verify notification was sent
      expect(notificationCount, greaterThan(0));
    });

    test('should handle complex multi-language words', () async {
      // Arrange: Create a complex word with multiple languages and parts of speech
      final complexWord = Word(
        word: 'complex_word',
        languageCodes: {LanguageCode.en, LanguageCode.es, LanguageCode.fr},
        partOfSpeech: {
          LanguageCode.en: PartOfSpeech.noun,
          LanguageCode.es: PartOfSpeech.verb,
          LanguageCode.fr: PartOfSpeech.adjective,
        },
        needsProcessing: true,
      );

      // Act: Create and retrieve the complex word
      final created = await service.createWord(complexWord);
      expect(created, isNotNull);

      final retrieved = await service.getWord('complex_word');

      // Assert: Verify all complex data was preserved
      expect(retrieved, isNotNull);
      expect(retrieved!.languageCodes, hasLength(3));
      expect(retrieved.partOfSpeech, hasLength(3));
      expect(retrieved.partOfSpeech[LanguageCode.en], equals(PartOfSpeech.noun));
      expect(retrieved.partOfSpeech[LanguageCode.es], equals(PartOfSpeech.verb));
      expect(retrieved.partOfSpeech[LanguageCode.fr], equals(PartOfSpeech.adjective));
    });

    test('dependency injection concept demonstration', () {
      // Test service (uses fake Firebase)
      final testService = WordDataService(repository: mockRepo);
      expect(testService, isNotNull);
      expect(testService, isA<ChangeNotifier>());
      
      // Note: Production service would be WordDataService() without injection
      // but we can't test it here without Firebase initialization
    });
  });

  group('WordDataService Notification Tests', () {
    test('should notify listeners when data changes', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = WordDataService(repository: mockRepo);
      var notificationCount = 0;
      
      service.addListener(() {
        notificationCount++;
      });
      
      // In a real implementation, calling service methods that change data
      // would trigger notifyListeners() and increment the count
      
      // Since we verified this works in the main tests above, this is just structure demo
      expect(service, isA<ChangeNotifier>());
    });

    test('should handle listener removal', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      final service = WordDataService(repository: mockRepo);
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

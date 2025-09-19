import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:baby_words_tracker/util/language_code.dart';

import '../test_helpers/firebase_test_helpers.dart';
import '../test_helpers/mock_data.dart';

void main() {
  group('Firestore Integration Tests', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() async {
      FirebaseTestHelpers.setupFirebaseMocks();
      fakeFirestore = FirebaseTestHelpers.fakeFirestore;
      await FirebaseTestHelpers.setupTestData();
    });

    tearDown(() {
      FirebaseTestHelpers.tearDown();
    });

    group('Child Data Operations', () {
      test('should create and retrieve child data', () async {
        final testChild = MockData.createMockChild(
          id: 'integration-test-child',
          name: 'Integration Test Child',
          wordCount: 10,
          languages: [LanguageCode.en],
        );

        // Create child in Firestore
        await fakeFirestore
            .collection('Child')
            .doc(testChild.id!)
            .set(testChild.toMap());

        // Retrieve and verify
        final doc = await fakeFirestore
            .collection('Child')
            .doc(testChild.id!)
            .get();

        expect(doc.exists, isTrue);
        expect(doc.data()?['name'], equals('Integration Test Child'));
        expect(doc.data()?['wordCount'], equals(10));
      });

      test('should update child word count', () async {
        final childId = 'word-count-test-child';
        final initialChild = MockData.createMockChild(
          id: childId,
          name: 'Word Count Test',
          wordCount: 5,
        );

        // Create initial child
        await fakeFirestore
            .collection('Child')
            .doc(childId)
            .set(initialChild.toMap());

        // Update word count
        await fakeFirestore
            .collection('Child')
            .doc(childId)
            .update({'wordCount': 15});

        // Verify update
        final updatedDoc = await fakeFirestore
            .collection('Child')
            .doc(childId)
            .get();

        expect(updatedDoc.data()?['wordCount'], equals(15));
      });

      test('should query children by parent ID', () async {
        final parentId = 'test-parent-123';
        
        // Create multiple children for the same parent
        for (int i = 0; i < 3; i++) {
          final child = MockData.createMockChild(
            id: 'child-$i',
            name: 'Child $i',
            parentIDs: [parentId],
          );
          
          await fakeFirestore
              .collection('Child')
              .doc(child.id!)
              .set(child.toMap());
        }

        // Query children by parent ID
        final querySnapshot = await fakeFirestore
            .collection('Child')
            .where('parentIDs', arrayContains: parentId)
            .get();

        expect(querySnapshot.docs.length, equals(3));
        
        for (final doc in querySnapshot.docs) {
          expect(doc.data()['parentIDs'], contains(parentId));
        }
      });
    });

    group('Word Data Operations', () {
      test('should create and manage vocabulary', () async {
        // Create a set of words
        final words = [
          MockData.createMockWord(word: 'apple', languageCodes: {LanguageCode.en}),
          MockData.createMockWord(word: 'manzana', languageCodes: {LanguageCode.es}),
          MockData.createMockWord(word: 'water', languageCodes: {LanguageCode.en}),
        ];

        // Add words to Firestore
        for (final word in words) {
          await fakeFirestore
              .collection('Word')
              .doc(word.word)
              .set(word.toMap());
        }

        // Verify all words were added
        for (final word in words) {
          final doc = await fakeFirestore
              .collection('Word')
              .doc(word.word)
              .get();
          
          expect(doc.exists, isTrue);
          expect(doc.data()?['needsProcessing'], equals(false));
        }

        // Query words by language
        final englishWords = await fakeFirestore
            .collection('Word')
            .where('languageCodes', arrayContains: 'en')
            .get();

        expect(englishWords.docs.length, greaterThanOrEqualTo(2));
      });

      test('should handle bilingual word tracking', () async {
        final bilingualWord = MockData.createMockWord(
          word: 'hello-hola',
          languageCodes: {LanguageCode.en, LanguageCode.es},
        );

        await fakeFirestore
            .collection('Word')
            .doc(bilingualWord.word)
            .set(bilingualWord.toMap());

        // Verify the word supports both languages
        final doc = await fakeFirestore
            .collection('Word')
            .doc(bilingualWord.word)
            .get();

        final languageCodes = List<String>.from(doc.data()?['languageCodes'] ?? []);
        expect(languageCodes, contains('en'));
        expect(languageCodes, contains('es'));
      });
    });

    group('Parent-Child Relationships', () {
      test('should maintain parent-child data consistency', () async {
        final parentId = 'consistency-test-parent';
        final childIds = ['child-a', 'child-b', 'child-c'];

        // Create parent
        final parent = MockData.createMockParent(
          id: parentId,
          childIDs: childIds,
        );
        await fakeFirestore
            .collection('Parent')
            .doc(parentId)
            .set(parent.toMap());

        // Create children
        for (final childId in childIds) {
          final child = MockData.createMockChild(
            id: childId,
            name: 'Child $childId',
            parentIDs: [parentId],
          );
          await fakeFirestore
              .collection('Child')
              .doc(childId)
              .set(child.toMap());
        }

        // Verify parent has references to all children
        final parentDoc = await fakeFirestore
            .collection('Parent')
            .doc(parentId)
            .get();
        
        final parentChildIds = List<String>.from(parentDoc.data()?['childIDs'] ?? []);
        expect(parentChildIds.length, equals(3));
        
        for (final childId in childIds) {
          expect(parentChildIds, contains(childId));
        }

        // Verify each child references the parent
        for (final childId in childIds) {
          final childDoc = await fakeFirestore
              .collection('Child')
              .doc(childId)
              .get();
          
          final childParentIds = List<String>.from(childDoc.data()?['parentIDs'] ?? []);
          expect(childParentIds, contains(parentId));
        }
      });
    });

    group('Data Analytics Simulation', () {
      test('should track word learning progress over time', () async {
        final childId = 'progress-tracking-child';
        
        // Create child
        final child = MockData.createMockChild(
          id: childId,
          name: 'Progress Tracker',
          wordCount: 0,
        );
        await fakeFirestore
            .collection('Child')
            .doc(childId)
            .set(child.toMap());

        // Simulate progress over time
        final progressData = [
          {'date': '2024-01-01', 'wordCount': 10},
          {'date': '2024-02-01', 'wordCount': 25},
          {'date': '2024-03-01', 'wordCount': 45},
          {'date': '2024-04-01', 'wordCount': 70},
        ];

        // Store progress data
        for (int i = 0; i < progressData.length; i++) {
          await fakeFirestore
              .collection('WordTracking')
              .doc('$childId-progress-$i')
              .set({
                'childId': childId,
                ...progressData[i],
              });
        }

        // Query progress data
        final progressQuery = await fakeFirestore
            .collection('WordTracking')
            .where('childId', isEqualTo: childId)
            .get();

        expect(progressQuery.docs.length, equals(4));

        // Verify data integrity
        final progressList = progressQuery.docs
            .map((doc) => doc.data())
            .toList();

        expect(progressList.first['wordCount'], equals(10));
        expect(progressList.last['wordCount'], equals(70));

        // Calculate total growth
        final totalGrowth = progressList.last['wordCount'] - progressList.first['wordCount'];
        expect(totalGrowth, equals(60));
      });
    });

    group('Error Scenarios', () {
      test('should handle missing documents gracefully', () async {
        // Try to get a non-existent document
        final doc = await fakeFirestore
            .collection('Child')
            .doc('non-existent-child')
            .get();

        expect(doc.exists, isFalse);
        expect(doc.data(), isNull);
      });

      test('should handle empty query results', () async {
        // Query for children with a non-existent parent
        final querySnapshot = await fakeFirestore
            .collection('Child')
            .where('parentIDs', arrayContains: 'non-existent-parent')
            .get();

        expect(querySnapshot.docs, isEmpty);
      });

      test('should handle data type mismatches', () async {
        // Create a document with incorrect data types
        await fakeFirestore
            .collection('Child')
            .doc('invalid-data-child')
            .set({
              'name': 'Valid Name',
              'wordCount': 'not-a-number', // Invalid type
              'parentIDs': 'not-an-array', // Invalid type
            });

        final doc = await fakeFirestore
            .collection('Child')
            .doc('invalid-data-child')
            .get();

        expect(doc.exists, isTrue);
        expect(doc.data()?['name'], equals('Valid Name'));
        // In a real app, you'd handle these validation errors
        expect(doc.data()?['wordCount'], equals('not-a-number'));
      });
    });
  });
}

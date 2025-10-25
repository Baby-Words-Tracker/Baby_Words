import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Word Model Tests', () {
    late Word testWord;

    setUp(() {
      testWord = Word(
        word: 'hello',
        languageDetails: {
          LanguageCode.en: WordLanguageDetail(
            lemma: 'hello',
            primaryPartOfSpeech: 'INTERJECTION',
            allPOS: const ['INTERJECTION'],
          ),
        },
        needsProcessing: false,
      );
    });

    test('should create a word with language details', () {
      expect(testWord.word, equals('hello'));
      expect(testWord.languageCodes, contains(LanguageCode.en));
      expect(
        testWord.partOfSpeech[LanguageCode.en],
        equals(PartOfSpeech.interjection),
      );
      expect(testWord.needsProcessing, isFalse);
    });

    test('should create word needing processing by default', () {
      final processingWord = Word(
        word: 'casa',
        languageDetails: {
          LanguageCode.es: WordLanguageDetail(
            primaryPartOfSpeech: 'NOUN',
            allPOS: const ['NOUN'],
          ),
        },
      );

      expect(processingWord.needsProcessing, isFalse);
      expect(
        processingWord.partOfSpeech[LanguageCode.es],
        equals(PartOfSpeech.noun),
      );
    });

    test('copyWith should preserve language details unless overridden', () {
      final copiedWord = testWord.copyWith(
        word: 'goodbye',
        needsProcessing: true,
      );

      expect(copiedWord.word, equals('goodbye'));
      expect(copiedWord.needsProcessing, isTrue);
      expect(copiedWord.languageDetails, equals(testWord.languageDetails));
    });

    test('toMap serialises language details', () {
      final map = testWord.toMap();

      expect(map['languageCodes'], equals(['en']));
      expect(map['languageDetails'], isA<Map<String, dynamic>>());
      expect(
        (map['languageDetails']['en'] as Map<String, dynamic>)['primaryPartOfSpeech'],
        equals('INTERJECTION'),
      );
    });

    test('should handle multiple languages', () {
      final multilingualWord = Word(
        word: 'book',
        languageDetails: {
          LanguageCode.en: WordLanguageDetail(
            primaryPartOfSpeech: 'NOUN',
            allPOS: const ['NOUN'],
          ),
          LanguageCode.es: WordLanguageDetail(
            primaryPartOfSpeech: 'NOUN',
            allPOS: const ['NOUN'],
          ),
        },
      );

      expect(multilingualWord.languageCodes, hasLength(2));
      expect(multilingualWord.partOfSpeech, hasLength(2));
      expect(
        multilingualWord.partOfSpeech[LanguageCode.en],
        equals(PartOfSpeech.noun),
      );
      expect(
        multilingualWord.partOfSpeech[LanguageCode.es],
        equals(PartOfSpeech.noun),
      );
    });

    test('createUpdateMap builds basic payload', () {
      final updateMap = Word.createUpdateMap(
        languageCodes: {LanguageCode.es},
        needsProcessing: true,
      );

      expect(updateMap['languageCodes'], equals(['es']));
      expect(updateMap['needsProcessing'], isTrue);
      expect(updateMap.containsKey('languageDetails'), isFalse);
    });

    test('equality considers language details', () {
      final identicalWord = Word(
        word: 'hello',
        languageDetails: {
          LanguageCode.en: WordLanguageDetail(
            lemma: 'hello',
            primaryPartOfSpeech: 'INTERJECTION',
            allPOS: const ['INTERJECTION'],
          ),
        },
        needsProcessing: false,
      );

      final differentWord = testWord.copyWith(word: 'hi');

      expect(testWord, equals(identicalWord));
      expect(testWord, isNot(equals(differentWord)));
      expect(testWord.hashCode, equals(identicalWord.hashCode));
    });

    test('Word -> JSON round trip works', () {
      final json = testWord.toJson();
      final roundTrip = Word.fromJson(json);

      expect(roundTrip, equals(testWord));
    });
  });
}

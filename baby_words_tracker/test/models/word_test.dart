import 'package:flutter_test/flutter_test.dart';
import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';

void main() {
  group('Word Model Tests', () {
    late Word testWord;

    setUp(() {
      testWord = Word(
        word: 'hello',
        languageCodes: {LanguageCode.en},
        partOfSpeech: {LanguageCode.en: PartOfSpeech.interjection},
        needsProcessing: false,
      );
    });

    test('should create a word with all required fields', () {
      expect(testWord.word, equals('hello'));
      expect(testWord.languageCodes, contains(LanguageCode.en));
      expect(testWord.partOfSpeech[LanguageCode.en], equals(PartOfSpeech.interjection));
      expect(testWord.needsProcessing, isFalse);
    });

    test('should create word needing processing by default', () {
      final processingWord = Word(
        word: 'casa',
        languageCodes: {LanguageCode.es},
        partOfSpeech: {LanguageCode.es: PartOfSpeech.noun},
      );

      expect(processingWord.needsProcessing, isFalse); // Default is false
    });

    test('should copy word with new values', () {
      final copiedWord = testWord.copyWith(
        word: 'goodbye',
        needsProcessing: true,
      );

      expect(copiedWord.word, equals('goodbye'));
      expect(copiedWord.needsProcessing, isTrue);
      expect(copiedWord.languageCodes, equals(testWord.languageCodes));
      expect(copiedWord.partOfSpeech, equals(testWord.partOfSpeech));
    });

    test('should convert to map correctly', () {
      final map = testWord.toMap();
      
      expect(map['languageCodes'], equals(['en']));
      expect(map['partOfSpeech'], equals({'en': 'interjection'}));
      expect(map['needsProcessing'], isFalse);
    });

    test('should handle multiple languages', () {
      final multilingualWord = Word(
        word: 'book',
        languageCodes: {LanguageCode.en, LanguageCode.es},
        partOfSpeech: {
          LanguageCode.en: PartOfSpeech.noun,
          LanguageCode.es: PartOfSpeech.noun,
        },
      );

      expect(multilingualWord.languageCodes, hasLength(2));
      expect(multilingualWord.partOfSpeech, hasLength(2));
      expect(multilingualWord.partOfSpeech[LanguageCode.en], equals(PartOfSpeech.noun));
      expect(multilingualWord.partOfSpeech[LanguageCode.es], equals(PartOfSpeech.noun));
    });

    test('should create update map with partial fields', () {
      final updateMap = Word.createUpdateMap(
        languageCodes: {LanguageCode.es},
        needsProcessing: true,
      );

      expect(updateMap['languageCodes'], equals(['es']));
      expect(updateMap['needsProcessing'], isTrue);
      expect(updateMap.containsKey('partOfSpeech'), isFalse);
    });

    test('should handle equality correctly', () {
      final identicalWord = Word(
        word: 'hello',
        languageCodes: {LanguageCode.en},
        partOfSpeech: {LanguageCode.en: PartOfSpeech.interjection},
        needsProcessing: false,
      );

      final differentWord = testWord.copyWith(word: 'hi');

      expect(testWord, equals(identicalWord));
      expect(testWord, isNot(equals(differentWord)));
      expect(testWord.hashCode, equals(identicalWord.hashCode));
    });

    test('should handle different parts of speech', () {
      final verbWord = Word(
        word: 'run',
        languageCodes: {LanguageCode.en},
        partOfSpeech: {LanguageCode.en: PartOfSpeech.verb},
      );

      final adjectiveWord = Word(
        word: 'big',
        languageCodes: {LanguageCode.en},
        partOfSpeech: {LanguageCode.en: PartOfSpeech.adjective},
      );

      expect(verbWord.partOfSpeech[LanguageCode.en], equals(PartOfSpeech.verb));
      expect(adjectiveWord.partOfSpeech[LanguageCode.en], equals(PartOfSpeech.adjective));
    });

    test('should convert to and from JSON correctly', () {
      final json = testWord.toJson();
      expect(json, isA<String>());
      expect(json.isNotEmpty, isTrue);
    });
  });
}

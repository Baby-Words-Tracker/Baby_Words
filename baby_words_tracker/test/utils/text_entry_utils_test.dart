import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/text_entry_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normaliseForDocumentId', () {
    test('trims, lowercases, and collapses whitespace', () {
      expect(
        normaliseForDocumentId('  Mi  Palabra  '),
        'mi palabra',
      );
    });
  });

  group('extractWords', () {
    test('splits phrase into normalised words', () {
      expect(
        extractWords('¡Hola   Mundo!'),
        ['hola', 'mundo'],
      );
    });
  });

  group('validateWord', () {
    test('returns null when word is valid', () {
      expect(validateWord('Niño'), isNull);
    });

    test('returns error when word contains digits', () {
      expect(validateWord('palabra1'), isNotNull);
    });
  });

  group('validatePhrase', () {
    test('returns null for valid phrase', () {
      expect(validatePhrase('Buenos dias'), isNull);
    });

    test('rejects phrases with punctuation', () {
      expect(validatePhrase('Hola!'), isNotNull);
    });
  });

  group('languageDisplayName', () {
    test('uses localized display names', () {
      expect(languageDisplayName(LanguageCode.es), 'Spanish');
    });
  });
}

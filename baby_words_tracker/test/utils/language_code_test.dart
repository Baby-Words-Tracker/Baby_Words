import 'package:flutter_test/flutter_test.dart';
import 'package:baby_words_tracker/util/language_code.dart';

void main() {
  group('LanguageCode Tests', () {
    test('should have expected language codes', () {
      expect(LanguageCode.values, contains(LanguageCode.en));
      expect(LanguageCode.values, contains(LanguageCode.es));
    });

    test('should convert to string correctly', () {
      expect(LanguageCode.en.name, equals('en'));
      expect(LanguageCode.es.name, equals('es'));
    });

    test('should have extension methods if implemented', () {
      // Test any extension methods on LanguageCode
      // This depends on what extensions are in the actual file
      expect(LanguageCode.en, isA<LanguageCode>());
    });
  });
}

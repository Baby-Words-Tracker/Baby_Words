import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';

/// Helper class to provide mock data for testing
class MockData {
  
  // Mock Children
  static Child get mockChild1 => Child(
    id: 'child-1',
    birthday: DateTime(2020, 1, 15),
    name: 'Emma',
    language: [LanguageCode.en],
    wordCount: 25,
    parentIDs: ['parent-1'],
  );

  static Child get mockChild2 => Child(
    id: 'child-2',
    birthday: DateTime(2019, 6, 10),
    name: 'Lucas',
    language: [LanguageCode.en, LanguageCode.es],
    wordCount: 50,
    parentIDs: ['parent-1', 'parent-2'],
  );

  static List<Child> get mockChildren => [mockChild1, mockChild2];

  // Mock Words
  static Word get mockWordHello => Word(
    word: 'hello',
    languageCodes: {LanguageCode.en},
    partOfSpeech: {LanguageCode.en: PartOfSpeech.interjection},
    needsProcessing: false,
  );

  static Word get mockWordMama => Word(
    word: 'mama',
    languageCodes: {LanguageCode.en},
    partOfSpeech: {LanguageCode.en: PartOfSpeech.noun},
    needsProcessing: false,
  );

  static Word get mockWordRun => Word(
    word: 'run',
    languageCodes: {LanguageCode.en},
    partOfSpeech: {LanguageCode.en: PartOfSpeech.verb},
    needsProcessing: false,
  );

  static List<Word> get mockWords => [mockWordHello, mockWordMama, mockWordRun];

  // Mock Parents
  static Parent get mockParent1 => Parent(
    id: 'parent-1',
    childIDs: ['child-1', 'child-2'],
  );

  static Parent get mockParent2 => Parent(
    id: 'parent-2',
    childIDs: ['child-2'],
  );

  static List<Parent> get mockParents => [mockParent1, mockParent2];

  // Helper methods for creating test data
  static Parent createMockParent({
    String? id,
    List<String>? childIDs,
  }) {
    return Parent(
      id: id ?? 'test-parent',
      childIDs: childIDs ?? ['test-child'],
    );
  }
  static Child createMockChild({
    String? id,
    String? name,
    DateTime? birthday,
    List<LanguageCode>? languages,
    int? wordCount,
    List<String>? parentIDs,
  }) {
    return Child(
      id: id ?? 'test-child',
      birthday: birthday ?? DateTime(2020, 1, 1),
      name: name ?? 'Test Child',
      language: languages ?? [LanguageCode.en],
      wordCount: wordCount ?? 0,
      parentIDs: parentIDs ?? ['test-parent'],
    );
  }

  static Word createMockWord({
    String? word,
    Set<LanguageCode>? languageCodes,
    Map<LanguageCode, PartOfSpeech>? partOfSpeech,
    bool? needsProcessing,
  }) {
    return Word(
      word: word ?? 'test-word',
      languageCodes: languageCodes ?? {LanguageCode.en},
      partOfSpeech: partOfSpeech ?? {LanguageCode.en: PartOfSpeech.noun},
      needsProcessing: needsProcessing ?? false,
    );
  }
}

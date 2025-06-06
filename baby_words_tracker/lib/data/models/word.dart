// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:collection/collection.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';

class Word {
  static String collectionName = 'Word';

  final String word;
  final List<LanguageCode> languageCodes;
  final Map<LanguageCode, PartOfSpeech> partOfSpeech;
  final Map<LanguageCode, String?> definition;

  Word({
    required this.word,
    required this.languageCodes,
    required this.partOfSpeech,
    required this.definition,
  });

  Word copyWith({
    String? word,
    List<LanguageCode>? languageCodes,
    Map<LanguageCode, PartOfSpeech>? partOfSpeech,
    Map<LanguageCode, String?>? definition,
  }) {
    return Word(
      word: word ?? this.word,
      languageCodes: languageCodes ?? this.languageCodes,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      definition: definition ?? this.definition,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'languageCodes': languageCodes.map((x) => x.name).toList(),
      'partOfSpeech': partOfSpeech.map((key, value) =>
          MapEntry(key.displayCode, value.name)), // partOfSpeech.name,
      'definition':
          definition.map((key, value) => MapEntry(key.displayCode, value)),
    };
  }

  factory Word.fromMap(Map<String, dynamic> map, String id) {
    return Word(
      word: id,
      languageCodes: (map['languageCodes'] as List<dynamic>?)
              ?.whereType<String>()
              .map((i) => LanguageCode.values.byName(i))
              .toList() ??
          [],
      partOfSpeech: (map['partOfSpeech'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(
                LanguageCode.values.firstWhere((e) => e.name == key),
                PartOfSpeech.values.byName(value),
              )),
      definition: (map['definition'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(
                LanguageCode.values.firstWhere((e) => e.name == key),
                value,
              )),
    );
  }

  String toJson() => json.encode(toMap());

  factory Word.fromJson(String source, String id) =>
      Word.fromMap(json.decode(source) as Map<String, dynamic>, id);

  factory Word.fromDataWithId(DataWithId source) {
    return Word.fromMap(source.data, source.id);
  }

  @override
  String toString() {
    return 'Word(word: $word, languageCodes: $languageCodes, partOfSpeech: $partOfSpeech, definition: $definition)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Word) return false;

    final listEquals = const DeepCollectionEquality().equals;

    return other.word == word &&
        listEquals(other.languageCodes, languageCodes) &&
        other.partOfSpeech == partOfSpeech &&
        other.definition == definition;
  }

  @override
  int get hashCode => Object.hashAll([
        word,
        const DeepCollectionEquality().hash(languageCodes),
        partOfSpeech,
        definition,
      ]);
}

// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:baby_words_tracker/util/collection_name.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:collection/collection.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';

class Word {
  static CollectionName collectionName = CollectionName(
    'Word',
    demoPrefix: "",
  );

  final String word;
  final Set<LanguageCode> languageCodes;
  final Map<LanguageCode, PartOfSpeech> partOfSpeech;
  final bool needsProcessing;

  Word({
    required this.word,
    required this.languageCodes,
    required this.partOfSpeech,
    this.needsProcessing = false,
  });

  Word copyWith({
    String? word,
    Set<LanguageCode>? languageCodes,
    Map<LanguageCode, PartOfSpeech>? partOfSpeech,
    bool? needsProcessing,
  }) {
    return Word(
      word: word ?? this.word,
      languageCodes: languageCodes ?? this.languageCodes,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      needsProcessing: needsProcessing ?? this.needsProcessing,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'languageCodes': languageCodes.map((x) => x.name).toList(),
      'partOfSpeech': partOfSpeech.map((langCodeKey, posVal) =>
          MapEntry(langCodeKey.name, posVal.name)), // partOfSpeech.name,
      'needsProcessing': needsProcessing,
    };
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      word: map['id'] as String,
      languageCodes: (map['languageCodes'] as List<dynamic>?)
              ?.whereType<String>()
              .map((i) => LanguageCode.values.byName(i))
              .toSet() ??
          {},
      partOfSpeech: (map['partOfSpeech'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(
                LanguageCodeExtension.fromString(key),
                PartofspeechExtension.fromString(value),
              )),
      needsProcessing: map['needsProcessing'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Word.fromJson(String source) =>
      Word.fromMap(json.decode(source) as Map<String, dynamic>);

  factory Word.fromDataWithId(DataWithId source) {
    Map<String, dynamic> data = source.data;
    data['id'] = source.id; // Use the id as the word
    return Word.fromMap(data);
  }

  static Map<String, dynamic> createUpdateMap({
    Set<LanguageCode>? languageCodes,
    Map<LanguageCode, PartOfSpeech>? partOfSpeech,
    bool? needsProcessing,
  }) {
    // Create a map for updating a word
    Map<String, dynamic> map = {};
    if (languageCodes != null) {
      map['languageCodes'] = languageCodes.map((x) => x.name).toList();
    }
    if (partOfSpeech != null) {
      map['partOfSpeech'] =
          partOfSpeech.map((k, v) => MapEntry(k.name, v.name));
    }
    if (needsProcessing != null) {
      map['needsProcessing'] = needsProcessing;
    }
    return map;
  }

  @override
  String toString() {
    return 'Word(word: $word, languageCodes: $languageCodes, partOfSpeech: $partOfSpeech, needsProcessing: $needsProcessing)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Word) return false;

    final listEquals = const DeepCollectionEquality().equals;

    return other.word == word &&
        listEquals(other.languageCodes, languageCodes) &&
        listEquals(other.partOfSpeech, partOfSpeech) &&
        other.needsProcessing == needsProcessing;
  }

  @override
  int get hashCode => Object.hashAll([
        word,
        const DeepCollectionEquality().hash(languageCodes),
        const DeepCollectionEquality().hash(partOfSpeech),
        needsProcessing,
      ]);
}

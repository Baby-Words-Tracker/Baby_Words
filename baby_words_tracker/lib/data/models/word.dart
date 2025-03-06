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
  final Map<LanguageCode,String?> definition;


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
      'partOfSpeech': partOfSpeech,
      'definition': definition,
    };
  }

  factory Word.fromMap(Map<String, dynamic> map, String id) {
    return Word(
      word: id,
      languageCodes: (map['languageCodes'] as List<dynamic>?)
        ?.whereType<String>()
        .map((i) => LanguageCode.values.byName(i))
        .toList() ?? [],
      partOfSpeech: map['partOfSpeech'],//(map['partOfSpeech'] as String?) != null ? PartOfSpeech.values.byName(map['partOfSpeech'] as String) : PartOfSpeech.unknown,
      definition: (map['definition'] as Map<String, String>)
                  .map((i, j) => {LanguageCode.values.byName(i): j})?? {},
    );
  }

  String toJson() => json.encode(toMap());

  factory Word.fromJson(String source, String id) => Word.fromMap(json.decode(source) as Map<String, dynamic>, id);

  factory Word.fromDataWithId(DataWithId source) {
    return Word.fromMap(source.data, source.id); 
  }

  @override
  String toString() {
    return 'Word(word: $word, languageCodes: $languageCodes, partOfSpeech: $partOfSpeech, definition: $definition)';
  }

  @override
  bool operator ==(covariant Word other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;
  
    return 
      other.word == word &&
      listEquals(other.languageCodes, languageCodes) &&
      other.partOfSpeech == partOfSpeech &&
      other.definition == definition;
  }

  @override
  int get hashCode {
    return word.hashCode ^
      languageCodes.hashCode ^
      partOfSpeech.hashCode ^
      definition.hashCode;
  }
}

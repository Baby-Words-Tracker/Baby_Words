// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:collection/collection.dart';

class Word {

  final String word;
  final List<LanguageCode> languageCodes;
  final PartOfSpeech partOfSpeech;
  final String definition;


  Word({
    required this.word,
    required this.languageCodes,
    required this.partOfSpeech,
    required this.definition,
  });

  Word copyWith({
    String? word,
    List<LanguageCode>? languageCodes,
    PartOfSpeech? partOfSpeech,
    String? definition,
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
      'word': word,
      'languageCodes': languageCodes.map((x) => x.name).toList(),
      'partOfSpeech': partOfSpeech.name,
      'definition': definition,
    };
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      word: map['word'] as String,
      languageCodes: List<LanguageCode>.from((map['languageCodes'] as List<String>).map<LanguageCode>((x) => LanguageCode.values.byName(x))),
      partOfSpeech: PartOfSpeech.values.byName(map['partOfSpeech'] as String),
      definition: map['definition'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Word.fromJson(String source) => Word.fromMap(json.decode(source) as Map<String, dynamic>);

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

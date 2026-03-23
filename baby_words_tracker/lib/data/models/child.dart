// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:baby_words_tracker/util/time_utils.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:collection/collection.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';

class Child {
  static String collectionName = 'Child';
  static String wordCountFieldName = 'wordCount';

  final String? id;
  final DateTime birthday;
  final String name;
  final List<LanguageCode> language;
  final int wordCount;
  final List<String> parentIDs;
  final String? sex; //added sex as a new field

  Child({
    this.id,
    required this.birthday,
    required this.name,
    required this.language,
    required this.wordCount,
    required this.parentIDs,
    required this.sex,
  });

  Child copyWith({
    String? id,
    DateTime? birthday,
    String? name,
    List<LanguageCode>? language,
    int? wordCount,
    List<String>? parentIDs,
    String? sex,
  }) {
    return Child(
      id: id ?? this.id,
      birthday: birthday ?? this.birthday,
      name: name ?? this.name,
      language: language ?? this.language,
      wordCount: wordCount ?? this.wordCount,
      parentIDs: parentIDs ?? this.parentIDs,
      sex: sex ?? this.sex,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'birthday': birthday,
      'name': name,
      'languageCodes': language.map((i) => i.name).toList(),
      wordCountFieldName: wordCount,
      'parentIDs': parentIDs as List<dynamic>,
      'sex': sex,
    };
  }

  factory Child.fromMap(Map<String, dynamic> map) {
    return Child(
      id: map['id'] as String?,
      birthday: map['birthday'] != null
          ? convertToDateTime(map['birthday'])
          : DateTime.fromMillisecondsSinceEpoch(0),
      name: (map['name'] ?? '') as String,
      language: (map['languageCodes'] as List<dynamic>?)
              ?.whereType<String>()
              .map((i) => LanguageCode.values.byName(i))
              .toList() ??
          [],
      wordCount: (map[wordCountFieldName] ?? 0) as int,
      parentIDs:
          (map['parentIDs'] as List<dynamic>?)?.whereType<String>().toList() ??
              [],
      sex: (map['sex'] ?? 'Unknown') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Child.fromJson(String source) =>
      Child.fromMap(json.decode(source) as Map<String, dynamic>);

  factory Child.fromDataWithId(DataWithId source) {
    Map<String, dynamic> data = source.data;
    data['id'] = source.id;
    return Child.fromMap(data);
  }

  @override
  String toString() {
    return 'Child(id: $id, birthday: $birthday, name: $name, wordCount: $wordCount, parentIDs: $parentIDs, sex: $sex)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Child) return false;

    final listEquals = const DeepCollectionEquality().equals;

    return other.id == id &&
        other.birthday == birthday &&
        other.name == name &&
        other.wordCount == wordCount &&
        listEquals(other.parentIDs, parentIDs) &&
        other.sex == sex;
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        birthday,
        name,
        wordCount,
        const DeepCollectionEquality().hash(parentIDs),
      ]);
}

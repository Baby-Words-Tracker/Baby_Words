// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:baby_words_tracker/data/listeners/i_document_listener.dart';
import 'package:collection/collection.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/util/language_code.dart';

class Parent {
  static String collectionName = 'Parent';

  final String id;
  final LanguageCode language;
  final List<String> childIDs;

  Parent({
    required this.id,
    this.language = LanguageCode.en,
    List<String>? childIDs,
  }) : childIDs = childIDs ?? [];

  Parent copyWith({
    String? id,
    LanguageCode? language,
    List<String>? childIDs,
  }) {
    return Parent(
      id: id ?? this.id,
      language: language ?? this.language,
      childIDs: childIDs ?? this.childIDs,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'language': language.displayCode,
      'childIDs': childIDs,
    };
  }

  factory Parent.fromMap(Map<String, dynamic> map) {
    return Parent(
      id: map['id'] as String,
      language: map['language'] == null // TODO: remove this null check later
          ? LanguageCode.en
          : LanguageCode.values.firstWhere((e) => e.name == map['language']),
      childIDs: (map['childIDs'] != null && map['childIDs'] is List)
          ? List<String>.from(map['childIDs'].whereType<String>())
          : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Parent.fromJson(String source) =>
      Parent.fromMap(json.decode(source) as Map<String, dynamic>);

  factory Parent.fromDataWithId(DataWithId source) {
    Map<String, dynamic> data = source.data;
    data['id'] = source.id;
    return Parent.fromMap(data);
  }

  static Map<String, dynamic> createUpdateMap(
      {List<String>? childIDs, LanguageCode? language}) {
    Map<String, dynamic> map = {};
    if (childIDs != null) map['childIDs'] = childIDs;
    if (language != null) map['language'] = language.displayCode;
    return map;
  }

  @override
  String toString() {
    return 'Parent(id: $id, childIDs: $childIDs)';
  }

  @override
  bool operator ==(covariant Parent other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.id == id && listEquals(other.childIDs, childIDs);
  }

  @override
  int get hashCode {
    return id.hashCode ^ childIDs.hashCode;
  }
}

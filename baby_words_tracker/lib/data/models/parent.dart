// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/shared_fields.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:collection/collection.dart';

class Parent {
  static String collectionName = 'Parent';

  final String id;
  final LanguageCode language;
  final List<String> childIDs;

  final bool consentFormComplete;
  final bool demographicSurveyComplete;
  final bool preStudySurveyComplete;

  final SharedFields sharedFields;

  Parent({
    required this.id,
    this.language = LanguageCode.en,
    List<String>? childIDs,
    this.consentFormComplete = false,
    this.demographicSurveyComplete = false,
    this.preStudySurveyComplete = false,
    SharedFields? sharedFields,
  })  : childIDs = childIDs ?? [],
        sharedFields = sharedFields ??
            const SharedFields(
              acceptedPrivacyPolicy: false,
              policyVersion: null,
              consentDate: null,
            );

  Parent copyWith({
    String? id,
    LanguageCode? language,
    List<String>? childIDs,
    bool? consentFormComplete,
    bool? demographicSurveyComplete,
    bool? preStudySurveyComplete,
    SharedFields? sharedFields,
  }) {
    return Parent(
      id: id ?? this.id,
      language: language ?? this.language,
      childIDs: childIDs ?? this.childIDs,
      consentFormComplete: this.consentFormComplete,
      demographicSurveyComplete: this.demographicSurveyComplete,
      preStudySurveyComplete: this.preStudySurveyComplete,
      sharedFields: this.sharedFields,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'language': language.displayCode,
      'childIDs': childIDs,
      'consentFormComplete': consentFormComplete,
      'demographicSurveyComplete': demographicSurveyComplete,
      'preStudySurveyComplete': preStudySurveyComplete,
      'sharedFields': sharedFields.toMap(),
    };
  }

  factory Parent.fromMap(Map<String, dynamic> map) {
    return Parent(
      id: map['id'] as String,
      language: map['language'] == null
          ? LanguageCode.en
          : LanguageCode.values.firstWhere((e) => e.name == map['language']),
      childIDs: (map['childIDs'] != null && map['childIDs'] is List)
          ? List<String>.from(map['childIDs'].whereType<String>())
          : [],
      consentFormComplete: map['consentFormComplete'] as bool? ?? false,
      demographicSurveyComplete:
          map['demographicSurveyComplete'] as bool? ?? false,
      preStudySurveyComplete: map['preStudySurveyComplete'] as bool? ?? false,
      sharedFields: SharedFields.fromMap(
          map['sharedFields'] as Map<String, dynamic>? ??
              const <String, dynamic>{}),
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

  static Map<String, dynamic> createUpdateMap({
    List<String>? childIDs,
    LanguageCode? language,
    bool? consentFormComplete,
    bool? demographicSurveyComplete,
    bool? preStudySurveyComplete,
    SharedFields? sharedFields,
  }) {
    Map<String, dynamic> map = {};
    if (childIDs != null) map['childIDs'] = childIDs;
    if (language != null) map['language'] = language.displayCode;
    if (consentFormComplete != null) {
      map['consentFormComplete'] = consentFormComplete;
    }
    if (demographicSurveyComplete != null) {
      map['demographicSurveyComplete'] = demographicSurveyComplete;
    }
    if (preStudySurveyComplete != null) {
      map['preStudySurveyComplete'] = preStudySurveyComplete;
    }
    if (sharedFields != null) map['sharedFields'] = sharedFields.toMap();

    return map;
  }

  @override
  String toString() {
    return 'Parent(id: $id, childIDs: $childIDs, language: $language, consentFormComplete: $consentFormComplete, demographicSurveyComplete: $demographicSurveyComplete, preStudySurveyComplete: $preStudySurveyComplete, sharedFields: $sharedFields)';
  }

  @override
  bool operator ==(covariant Parent other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.id == id &&
        listEquals(other.childIDs, childIDs) &&
        other.language == language &&
        other.consentFormComplete == consentFormComplete &&
        other.demographicSurveyComplete == demographicSurveyComplete &&
        other.preStudySurveyComplete == preStudySurveyComplete &&
        other.sharedFields == sharedFields;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        childIDs.hashCode ^
        language.hashCode ^
        consentFormComplete.hashCode ^
        demographicSurveyComplete.hashCode ^
        preStudySurveyComplete.hashCode ^
        sharedFields.hashCode;
  }
}

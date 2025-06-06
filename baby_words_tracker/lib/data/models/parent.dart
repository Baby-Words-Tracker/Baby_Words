// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/i_user_model.dart';
import 'package:baby_words_tracker/data/models/shared_fields.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/time_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

class Parent extends IUserModel {
  static String collectionName = 'Parent';

  final LanguageCode language;
  final List<String> childIDs;

  final bool consentFormComplete;
  final bool demographicSurveyComplete;
  final bool preStudySurveyComplete;

  Parent({
    required super.id,
    this.language = LanguageCode.en,
    List<String>? childIDs,
    this.consentFormComplete = false,
    this.demographicSurveyComplete = false,
    this.preStudySurveyComplete = false,
    super.acceptedPrivacyPolicy = false,
    super.policyVersion,
    super.consentDate,
  }) : childIDs = childIDs ?? [];

  Parent copyWith({
    String? id,
    LanguageCode? language,
    List<String>? childIDs,
    bool? consentFormComplete,
    bool? demographicSurveyComplete,
    bool? preStudySurveyComplete,
    bool? acceptedPrivacyPolicy,
    String? policyVersion,
    DateTime? consentDate,
  }) {
    return Parent(
      id: id ?? this.id,
      language: language ?? this.language,
      childIDs: childIDs ?? this.childIDs,
      consentFormComplete: this.consentFormComplete,
      demographicSurveyComplete: this.demographicSurveyComplete,
      preStudySurveyComplete: this.preStudySurveyComplete,
      acceptedPrivacyPolicy:
          acceptedPrivacyPolicy ?? this.acceptedPrivacyPolicy,
      policyVersion: policyVersion ?? this.policyVersion,
      consentDate: consentDate ?? this.consentDate,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      ...super.toMap(),
      'language': language.displayCode,
      'childIDs': childIDs,
      'consentFormComplete': consentFormComplete,
      'demographicSurveyComplete': demographicSurveyComplete,
      'preStudySurveyComplete': preStudySurveyComplete,
    };
  }

  factory Parent.fromMap(Map<String, dynamic> map) {
    return Parent(
      id: IUserModel.fromMapId(map),
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
      acceptedPrivacyPolicy: IUserModel.fromMapAcceptedPrivacyPolicy(map),
      policyVersion: IUserModel.fromMapPolicyVersion(map),
      consentDate: IUserModel.fromMapConsentDate(map),
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
    bool? acceptedPrivacyPolicy,
    String? policyVersion,
    DateTime? consentDate,
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

    map.addAll(IUserModel.createUpdateMap(
      acceptedPrivacyPolicy: acceptedPrivacyPolicy,
      policyVersion: policyVersion,
      consentDate: consentDate,
    ));

    return map;
  }

  @override
  String toString() {
    return 'Parent(${super.toString()}, childIDs: $childIDs, language: $language, consentFormComplete: $consentFormComplete, demographicSurveyComplete: $demographicSurveyComplete, preStudySurveyComplete: $preStudySurveyComplete)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Parent) return false;

    final listEquals = const DeepCollectionEquality().equals;

    return other.id == id &&
        listEquals(other.childIDs, childIDs) &&
        other.language == language &&
        other.consentFormComplete == consentFormComplete &&
        other.demographicSurveyComplete == demographicSurveyComplete &&
        other.preStudySurveyComplete == preStudySurveyComplete &&
        super == other;
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        const DeepCollectionEquality().hash(childIDs),
        language,
        consentFormComplete,
        demographicSurveyComplete,
        preStudySurveyComplete,
        super.hashCode,
      ]);
}

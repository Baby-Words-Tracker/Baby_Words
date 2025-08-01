// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/i_user_model.dart';
import 'package:baby_words_tracker/util/collection_name.dart';

class Researcher extends IUserModel {
  static CollectionName collectionName = CollectionName('Researcher');

  // final String id;
  final String? email;
  final String? name;
  final String? institution;
  final String? phoneNumber;

  // final SharedFields sharedFields;

  Researcher({
    required super.id,
    this.email,
    this.name,
    this.institution,
    this.phoneNumber,
    super.acceptedPrivacyPolicy = false,
    super.policyVersion,
    super.consentDate,
    super.isDemo = false,
  });

  Researcher copyWith({
    String? id,
    String? email,
    String? name,
    String? institution,
    String? phoneNumber,
    bool? acceptedPrivacyPolicy,
    String? policyVersion,
    DateTime? consentDate,
    bool? isDemo,
  }) {
    return Researcher(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      institution: institution ?? this.institution,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      acceptedPrivacyPolicy:
          acceptedPrivacyPolicy ?? this.acceptedPrivacyPolicy,
      policyVersion: policyVersion ?? this.policyVersion,
      consentDate: consentDate ?? this.consentDate,
      isDemo: isDemo ?? this.isDemo,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'name': name,
      'institution': institution,
      'phoneNumber': phoneNumber,
      ...super.toMap(),
    };
  }

  factory Researcher.fromMap(Map<String, dynamic> map) {
    return Researcher(
      id: IUserModel.fromMapId(map),
      email: map['email'] as String?,
      name: map['name'] as String?,
      institution: map['institution'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      acceptedPrivacyPolicy: IUserModel.fromMapAcceptedPrivacyPolicy(map),
      policyVersion: IUserModel.fromMapPolicyVersion(map),
      consentDate: IUserModel.fromMapConsentDate(map),
      isDemo: IUserModel.fromMapIsDemo(map),
    );
  }

  String toJson() => json.encode(toMap());

  factory Researcher.fromJson(String source) =>
      Researcher.fromMap(json.decode(source) as Map<String, dynamic>);

  factory Researcher.fromDataWithId(DataWithId source) {
    Map<String, dynamic> data = source.data;
    data['id'] = source.id;
    return Researcher.fromMap(data);
  }

  static Map<String, dynamic> createUpdateMap({
    String? email,
    String? name,
    String? institution,
    String? phoneNumber,
    bool? acceptedPrivacyPolicy,
    String? policyVersion,
    DateTime? consentDate,
    bool? isDemo,
  }) {
    Map<String, dynamic> updateData = <String, dynamic>{};
    if (email != null) updateData['email'] = email;
    if (name != null) updateData['name'] = name;
    if (institution != null) updateData['institution'] = institution;
    if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;

    updateData.addAll(
      IUserModel.createUpdateMap(
        acceptedPrivacyPolicy: acceptedPrivacyPolicy,
        policyVersion: policyVersion,
        consentDate: consentDate,
        isDemo: isDemo,
      ),
    );

    return updateData;
  }

  @override
  String toString() {
    return 'Researcher(${super.toString()}, email: $email, name: $name, institution: $institution, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Researcher) return false;

    return other.id == id &&
        other.email == email &&
        other.name == name &&
        other.institution == institution &&
        other.phoneNumber == phoneNumber &&
        super == other;
  }

  @override
  int get hashCode => Object.hashAll([
        email,
        name,
        institution,
        phoneNumber,
        super.hashCode,
      ]);
}

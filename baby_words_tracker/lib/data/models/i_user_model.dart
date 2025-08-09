// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:baby_words_tracker/util/collection_name.dart';
import 'package:baby_words_tracker/util/time_utils.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class IUserModel {
  static final CollectionName _collectionName = CollectionName('User');

  final String id;

  final UserType _userType;

  final bool _acceptedPrivacyPolicy;
  final String? _policyVersion;
  final DateTime? _consentDate;

  static CollectionName get collectionName => _collectionName;
  UserType get userType => _userType;
  bool get acceptedPrivacyPolicy => _acceptedPrivacyPolicy;
  String? get policyVersion => _policyVersion;
  DateTime? get consentDate => _consentDate;

  IUserModel({
    required this.id,
    required UserType userType,
    required bool acceptedPrivacyPolicy,
    String? policyVersion,
    DateTime? consentDate,
  })  : _userType = userType,
        _consentDate = consentDate,
        _acceptedPrivacyPolicy = acceptedPrivacyPolicy,
        _policyVersion = policyVersion;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userType': _userType.name,
      'acceptedPrivacyPolicy': _acceptedPrivacyPolicy,
      'policyVersion': _policyVersion,
      'consentDate': _consentDate?.millisecondsSinceEpoch,
    };
  }

  static String fromMapId(Map<String, dynamic> map) {
    return map['id'] as String;
  }

  static UserType fromMapUserType(Map<String, dynamic> map) {
    return UserType.values.byName(
        map['userType'] as String? ?? UserType.unauthenticated_type.name);
  }

  static bool fromMapAcceptedPrivacyPolicy(Map<String, dynamic> map) {
    return map['acceptedPrivacyPolicy'] as bool? ?? false;
  }

  static String? fromMapPolicyVersion(Map<String, dynamic> map) {
    return map['policyVersion'] as String?;
  }

  static DateTime? fromMapConsentDate(Map<String, dynamic> map) {
    return map['consentDate'] != null
        ? convertToDateTime(map['consentDate'] as Timestamp)
        : null;
  }

  // TODO: do we want to be able to update usertype from the app?
  //  I think only through cloud functions would be easiest so we don't
  //  have to worry about the firestore rules backflips that would be necessary
  //  to allow userType updates. We would need to update after changing user type claims
  static Map<String, dynamic> createUpdateMap({
    bool? acceptedPrivacyPolicy,
    String? policyVersion,
    DateTime? consentDate,
  }) {
    Map<String, dynamic> map = {};
    if (acceptedPrivacyPolicy != null) {
      map['acceptedPrivacyPolicy'] = acceptedPrivacyPolicy;
    }
    if (policyVersion != null) map['policyVersion'] = policyVersion;
    if (consentDate != null) {
      map['consentDate'] = consentDate;
    }
    return map;
  }

  @override
  String toString() {
    return 'IUserModel(id: $id, userType: ${_userType.name}, acceptedPrivacyPolicy: '
        '$_acceptedPrivacyPolicy, policyVersion: $_policyVersion, consentDate: $_consentDate)';
  }

  @override
  bool operator ==(covariant Object other) {
    if (identical(this, other)) return true;
    if (other is! IUserModel) return false;

    return other.id == id &&
        other._userType == _userType &&
        other._acceptedPrivacyPolicy == _acceptedPrivacyPolicy &&
        other._policyVersion == _policyVersion &&
        other._consentDate == _consentDate;
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        _userType,
        _acceptedPrivacyPolicy,
        _policyVersion,
        _consentDate,
      ]);
}

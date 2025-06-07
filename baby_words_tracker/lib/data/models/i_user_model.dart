// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:baby_words_tracker/util/time_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class IUserModel {
  final String id;

  final bool _acceptedPrivacyPolicy;
  final String? _policyVersion;
  final DateTime? _consentDate;

  bool get acceptedPrivacyPolicy => _acceptedPrivacyPolicy;
  String? get policyVersion => _policyVersion;
  DateTime? get consentDate => _consentDate;

  IUserModel({
    required this.id,
    required bool acceptedPrivacyPolicy,
    String? policyVersion,
    DateTime? consentDate,
  })  : _consentDate = consentDate,
        _acceptedPrivacyPolicy = acceptedPrivacyPolicy,
        _policyVersion = policyVersion;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'acceptedPrivacyPolicy': _acceptedPrivacyPolicy,
      'policyVersion': _policyVersion,
      'consentDate': _consentDate?.millisecondsSinceEpoch,
    };
  }

  static String fromMapId(Map<String, dynamic> map) {
    return map['id'] as String;
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
    return 'IUserModel(id: $id, acceptedPrivacyPolicy: $_acceptedPrivacyPolicy, policyVersion: $_policyVersion, consentDate: $_consentDate)';
  }

  @override
  bool operator ==(covariant Object other) {
    if (identical(this, other)) return true;
    if (other is! IUserModel) return false;

    return other.id == id &&
        other._acceptedPrivacyPolicy == _acceptedPrivacyPolicy &&
        other._policyVersion == _policyVersion &&
        other._consentDate == _consentDate;
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        _acceptedPrivacyPolicy,
        _policyVersion,
        _consentDate,
      ]);
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class SharedFields {
  final bool acceptedPrivacyPolicy;
  final String? policyVersion;
  final DateTime? consentDate;

  const SharedFields({
    required this.acceptedPrivacyPolicy,
    this.policyVersion,
    this.consentDate,
  });

  SharedFields copyWith({
    bool? acceptedPrivacyPolicy,
    String? policyVersion,
    DateTime? consentDate,
  }) {
    return SharedFields(
      acceptedPrivacyPolicy:
          acceptedPrivacyPolicy ?? this.acceptedPrivacyPolicy,
      policyVersion: policyVersion ?? this.policyVersion,
      consentDate: consentDate ?? this.consentDate,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'acceptedPrivacyPolicy': acceptedPrivacyPolicy,
      'policyVersion': policyVersion,
      'consentDate': consentDate?.millisecondsSinceEpoch,
    };
  }

  factory SharedFields.fromMap(Map<String, dynamic> map) {
    return SharedFields(
      acceptedPrivacyPolicy: map['acceptedPrivacyPolicy'] as bool,
      policyVersion:
          map['policyVersion'] != null ? map['policyVersion'] as String : null,
      consentDate: map['consentDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['consentDate'] as int)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory SharedFields.fromJson(String source) =>
      SharedFields.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'SharedFields(acceptedPrivacyPolicy: $acceptedPrivacyPolicy, policyVersion: $policyVersion, consentDate: $consentDate)';

  @override
  bool operator ==(covariant SharedFields other) {
    if (identical(this, other)) return true;

    return other.acceptedPrivacyPolicy == acceptedPrivacyPolicy &&
        other.policyVersion == policyVersion &&
        other.consentDate == consentDate;
  }

  @override
  int get hashCode =>
      acceptedPrivacyPolicy.hashCode ^
      policyVersion.hashCode ^
      consentDate.hashCode;
}

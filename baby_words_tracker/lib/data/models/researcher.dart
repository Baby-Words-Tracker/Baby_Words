// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Researcher {
  final String researcherID;
  final String email;
  final String name;
  final String institution;
  final String? phoneNumber;


  Researcher({
    required this.researcherID,
    required this.email,
    required this.name,
    required this.institution,
    this.phoneNumber,
  });

  Researcher copyWith({
    String? researcherID,
    String? email,
    String? name,
    String? institution,
    String? phoneNumber,
  }) {
    return Researcher(
      researcherID: researcherID ?? this.researcherID,
      email: email ?? this.email,
      name: name ?? this.name,
      institution: institution ?? this.institution,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'researcherID': researcherID,
      'email': email,
      'name': name,
      'institution': institution,
      'phoneNumber': phoneNumber,
    };
  }

  factory Researcher.fromMap(Map<String, dynamic> map) {
    return Researcher(
      researcherID: map['researcherID'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      institution: map['institution'] as String,
      phoneNumber: map['phoneNumber'] != null ? map['phoneNumber'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Researcher.fromJson(String source) => Researcher.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Researcher(researcherID: $researcherID, email: $email, name: $name, institution: $institution, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(covariant Researcher other) {
    if (identical(this, other)) return true;
  
    return 
      other.researcherID == researcherID &&
      other.email == email &&
      other.name == name &&
      other.institution == institution &&
      other.phoneNumber == phoneNumber;
  }

  @override
  int get hashCode {
    return researcherID.hashCode ^
      email.hashCode ^
      name.hashCode ^
      institution.hashCode ^
      phoneNumber.hashCode;
  }
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:baby_words_tracker/data/models/data_with_id.dart';

class Researcher {
  static String collectionName = 'Researcher'; 

  final String id;
  final String? email;
  final String? name;
  final String? institution;
  final String? phoneNumber;


  Researcher({
    required this.id,
    this.email,
    this.name,
    this.institution,
    this.phoneNumber,
  });

  Researcher copyWith({
    String? id,
    String? email,
    String? name,
    String? institution,
    String? phoneNumber,
  }) {
    return Researcher(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      institution: institution ?? this.institution,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'name': name,
      'institution': institution,
      'phoneNumber': phoneNumber,
    };
  }

  factory Researcher.fromMap(Map<String, dynamic> map) {
    return Researcher(
      id: map['id'] as String,
      email: map['email'] as String?,
      name: map['name'] as String?,
      institution: map['institution'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Researcher.fromJson(String source) => Researcher.fromMap(json.decode(source) as Map<String, dynamic>);

  factory Researcher.fromDataWithId(DataWithId source) {
    Map<String, dynamic> data = source.data;
    data['id'] = source.id;
    return Researcher.fromMap(data); 
  }

  static Map<String, dynamic> createUpdateMap({String? email, String? name, String? institution, String? phoneNumber}) {
    Map<String, dynamic> updateData = <String, dynamic>{};
    if (email != null) updateData['email'] = email;
    if (name != null) updateData['name'] = name;
    if (institution != null) updateData['institution'] = institution;
    if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
    return updateData;
  }

  @override
  String toString() {
    return 'Researcher(id: $id, email: $email, name: $name, institution: $institution, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(covariant Researcher other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.email == email &&
      other.name == name &&
      other.institution == institution &&
      other.phoneNumber == phoneNumber;
  }

  @override
  int get hashCode {
    return (id?.hashCode ?? 0) ^
      email.hashCode ^
      name.hashCode ^
      institution.hashCode ^
      phoneNumber.hashCode;
  }
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';


class Parent {
  final String? id;
  final String email;
  final String name;
  final List<String> childIDs;
  
  Parent({
    this.id,
    required this.email,
    required this.name,
    required this.childIDs,
  });


  Parent copyWith({
    String? id,
    String? email,
    String? name,
    List<String>? childIDs,
  }) {
    return Parent(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      childIDs: childIDs ?? this.childIDs,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'name': name,
      'childIDs': childIDs,
    };
  }

  factory Parent.fromMap(Map<String, dynamic> map) {
    return Parent(
      id: map['id'] as String?,
      email: map['email'] as String,
      name: map['name'] as String? ?? '',
      childIDs: (map['childIDs'] != null && map['childIDs'] is List) ? List<String>.from(map['childIDs'].whereType<String>()) : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Parent.fromJson(String source) => Parent.fromMap(json.decode(source) as Map<String, dynamic>);

  factory Parent.fromDataWithId(DataWithId source) {
    Map<String, dynamic> data = source.data;
    data['id'] = source.id;
    return Parent.fromMap(data); 
  }

  @override
  String toString() {
    return 'Parent(id: $id, email: $email, name: $name, childIDs: $childIDs)';
  }

  @override
  bool operator ==(covariant Parent other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;
  
    return 
      other.id == id &&
      other.email == email &&
      other.name == name &&
      listEquals(other.childIDs, childIDs);
  }

  @override
  int get hashCode {
    return (id?.hashCode ?? 0) ^
      email.hashCode ^
      name.hashCode ^
      childIDs.hashCode;
  }
}

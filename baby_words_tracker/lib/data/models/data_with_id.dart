
import 'package:cloud_firestore/cloud_firestore.dart';

class DataWithId {
  final String id;
  final Map<String, dynamic> data;

  DataWithId({
    required this.id,
    required this.data,
  });

  DataWithId copyWith({
    String? id,
    Map<String, dynamic>? data,
  }) {
    return DataWithId(
      id: id ?? this.id,
      data: data ?? this.data,
    );
  }

  factory DataWithId.fromFirestore(DocumentSnapshot doc) {
    return DataWithId(
      id: doc.id,
      data: doc.data() as Map<String, dynamic>, // Ensure this cast works for your use case
    );
  }

}
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime convertToDateTime(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate(); // Firestore Timestamp → DateTime
  } else if (timestamp is int) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp); // Unix Epoch → DateTime
  } else if (timestamp is String) {
    return DateTime.tryParse(timestamp) ?? DateTime(1970, 1, 1); // ISO 8601 → DateTime
  } else {
    throw ArgumentError('Unsupported timestamp format: $timestamp');
  }
}
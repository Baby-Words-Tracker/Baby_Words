// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:baby_words_tracker/util/time_utils.dart';

import 'package:baby_words_tracker/data/models/data_with_id.dart';

class WordTracker {
  static String collectionName = 'WordTracker';

  final String? id; // The word being tracked, e.g., "mama", "dada"
  final DateTime firstUtterance;

  WordTracker({
    this.id,
    required this.firstUtterance,
  });

  WordTracker copyWith({
    String? id,
    DateTime? firstUtterance,
    int? numUtterances,
  }) {
    return WordTracker(
      id: id ?? this.id,
      firstUtterance: firstUtterance ?? this.firstUtterance,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'firstUtterance': firstUtterance,
    };
  }

  factory WordTracker.fromMap(Map<String, dynamic> map) {
    return WordTracker(
      id: map['id'] as String?,
      firstUtterance: map['firstUtterance'] != null
          ? convertToDateTime(map['firstUtterance'])
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String toJson() => json.encode(toMap());

  factory WordTracker.fromJson(String source) =>
      WordTracker.fromMap(json.decode(source) as Map<String, dynamic>);

  factory WordTracker.fromDataWithId(DataWithId source) {
    Map<String, dynamic> data = source.data;
    data['id'] = source.id;
    return WordTracker.fromMap(data);
  }

  static Map<String, dynamic> createUpdateMap({
    DateTime? firstUtterance,
  }) {
    Map<String, dynamic> map = {};

    if (firstUtterance != null) {
      map['firstUtterance'] = firstUtterance;
    }

    return map;
  }

  @override
  String toString() {
    return 'Wordtracker(wordID: $id, firstUtterance: $firstUtterance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WordTracker) return false;

    return other.id == id && other.firstUtterance == firstUtterance;
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        firstUtterance,
      ]);
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:baby_words_tracker/util/time_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WordTracker {
  final String? id;
  final DateTime firstUtterance;
  final int numUtterances;
  final String? videoID;


  WordTracker({
    this.id,
    required this.firstUtterance,
    required this.numUtterances,
    this.videoID,
  });

  WordTracker copyWith({
    String? id,
    DateTime? firstUtterance,
    int? numUtterances,
    String? videoID,
  }) {
    return WordTracker(
      id: id ?? this.id,
      firstUtterance: firstUtterance ?? this.firstUtterance,
      numUtterances: numUtterances ?? this.numUtterances,
      videoID: videoID ?? this.videoID,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'firstUtterance': firstUtterance,
      'numUtterances': numUtterances,
      'videoID': videoID,
    };
  }

  factory WordTracker.fromMap(Map<String, dynamic> map) {
    return WordTracker(
      firstUtterance: map['firstUtterance'] != null ? convertToDateTime(map['firstUtterance']) : DateTime.fromMillisecondsSinceEpoch(0),
      numUtterances: (map['numUtterances'] ?? 0) as int,
      videoID: map['videoID'] != null ? map['videoID'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory WordTracker.fromJson(String source) => WordTracker.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Wordtracker(wordID: $id, firstUtterance: $firstUtterance, numUtterances: $numUtterances, videoID: $videoID)';
  }

  @override
  bool operator ==(covariant WordTracker other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.firstUtterance == firstUtterance &&
      other.numUtterances == numUtterances &&
      other.videoID == videoID;
  }

  @override
  int get hashCode {
    return (id?.hashCode ?? 0) ^
      firstUtterance.hashCode ^
      numUtterances.hashCode ^
      (videoID?.hashCode ?? 0);
  }
}

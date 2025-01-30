// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Wordtracker {
  final String wordID;
  final DateTime firstUtterance;
  final int numUtterances;
  final String videoID;


  Wordtracker({
    required this.wordID,
    required this.firstUtterance,
    required this.numUtterances,
    required this.videoID,
  });

  Wordtracker copyWith({
    String? wordID,
    DateTime? firstUtterance,
    int? numUtterances,
    String? videoID,
  }) {
    return Wordtracker(
      wordID: wordID ?? this.wordID,
      firstUtterance: firstUtterance ?? this.firstUtterance,
      numUtterances: numUtterances ?? this.numUtterances,
      videoID: videoID ?? this.videoID,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'wordID': wordID,
      'firstUtterance': Timestamp.fromDate(firstUtterance),
      'numUtterances': numUtterances,
      'videoID': videoID,
    };
  }

  factory Wordtracker.fromMap(Map<String, dynamic> map) {
    return Wordtracker(
      wordID: map['wordID'] as String,
      firstUtterance: map['firstUtterance'] != Null ? (map['firstUtterance'] as Timestamp).toDate() :  DateTime.fromMillisecondsSinceEpoch(0),
      numUtterances: (map['numUtterances'] ?? 0) as int,
      videoID: (map['videoID'] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Wordtracker.fromJson(String source) => Wordtracker.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Wordtracker(wordID: $wordID, firstUtterance: $firstUtterance, numUtterances: $numUtterances, videoID: $videoID)';
  }

  @override
  bool operator ==(covariant Wordtracker other) {
    if (identical(this, other)) return true;
  
    return 
      other.wordID == wordID &&
      other.firstUtterance == firstUtterance &&
      other.numUtterances == numUtterances &&
      other.videoID == videoID;
  }

  @override
  int get hashCode {
    return wordID.hashCode ^
      firstUtterance.hashCode ^
      numUtterances.hashCode ^
      videoID.hashCode;
  }
}

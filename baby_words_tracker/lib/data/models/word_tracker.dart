// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:baby_words_tracker/util/time_utils.dart';

import 'package:baby_words_tracker/data/models/data_with_id.dart';

class WordTracker {
  static String collectionName = 'WordTracker';

  final String? id;
  final DateTime firstUtterance;
  final String? videoID;


  WordTracker({
    this.id,
    required this.firstUtterance,
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
      videoID: videoID ?? this.videoID,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'firstUtterance': firstUtterance,
      'videoID': videoID,
    };
  }

  factory WordTracker.fromMap(Map<String, dynamic> map) {
    return WordTracker(
      id: map['id'] as String?,
      firstUtterance: map['firstUtterance'] != null ? convertToDateTime(map['firstUtterance']) : DateTime.fromMillisecondsSinceEpoch(0),
      videoID: map['videoID'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory WordTracker.fromJson(String source) => WordTracker.fromMap(json.decode(source) as Map<String, dynamic>);

  factory WordTracker.fromDataWithId(DataWithId source) {
    Map<String, dynamic> data = source.data;
    data['id'] = source.id;
    return WordTracker.fromMap(data); 
  }

  @override
  String toString() {
    return 'Wordtracker(wordID: $id, firstUtterance: $firstUtterance, videoID: $videoID)';
  }

  @override
  bool operator ==(covariant WordTracker other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.firstUtterance == firstUtterance &&
      other.videoID == videoID;
  }

  @override
  int get hashCode {
    return (id?.hashCode ?? 0) ^
      firstUtterance.hashCode ^
      (videoID?.hashCode ?? 0);
  }
}

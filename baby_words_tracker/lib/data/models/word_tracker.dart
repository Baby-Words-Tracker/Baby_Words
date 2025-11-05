// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/time_utils.dart';

import 'package:baby_words_tracker/data/models/data_with_id.dart';

class WordTracker {
  static String collectionName = 'WordTracker';

  final String? id; // The word being tracked, e.g., "mama", "dada"
  final DateTime firstUtterance;
  final LanguageCode? language;
  final String? note;
  final String? videoId;
  final String? phraseId;
  final String? phraseText;

  WordTracker({
    this.id,
    required this.firstUtterance,
    this.language,
    this.note,
    this.videoId,
    this.phraseId,
    this.phraseText,
  });

  WordTracker copyWith({
    String? id,
    DateTime? firstUtterance,
    LanguageCode? language,
    String? note,
    String? videoId,
    String? phraseId,
    String? phraseText,
  }) {
    return WordTracker(
      id: id ?? this.id,
      firstUtterance: firstUtterance ?? this.firstUtterance,
      language: language ?? this.language,
      note: note ?? this.note,
      videoId: videoId ?? this.videoId,
      phraseId: phraseId ?? this.phraseId,
      phraseText: phraseText ?? this.phraseText,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'firstUtterance': firstUtterance,
      if (language != null) 'language': language!.name,
      if (note != null && note!.isNotEmpty) 'note': note,
      if (videoId != null && videoId!.isNotEmpty) 'videoId': videoId,
      if (phraseId != null && phraseId!.isNotEmpty) 'phraseId': phraseId,
      if (phraseText != null && phraseText!.isNotEmpty)
        'phraseText': phraseText,
    };
  }

  factory WordTracker.fromMap(Map<String, dynamic> map) {
    return WordTracker(
      id: map['id'] as String?,
      firstUtterance: map['firstUtterance'] != null
          ? convertToDateTime(map['firstUtterance'])
          : DateTime.fromMillisecondsSinceEpoch(0),
      language: map['language'] is String
          ? LanguageCodeExtension.fromString(map['language'] as String)
          : null,
      note: map['note'] as String?,
      videoId: map['videoId'] as String?,
      phraseId: map['phraseId'] as String?,
      phraseText: map['phraseText'] as String?,
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
    LanguageCode? language,
    String? note,
    String? videoId,
    String? phraseId,
    String? phraseText,
  }) {
    Map<String, dynamic> map = {};

    if (firstUtterance != null) {
      map['firstUtterance'] = firstUtterance;
    }
    if (language != null) {
      map['language'] = language.name;
    }
    if (note != null) {
      map['note'] = note;
    }
    if (videoId != null) {
      map['videoId'] = videoId;
    }
    if (phraseId != null) {
      map['phraseId'] = phraseId;
    }
    if (phraseText != null) {
      map['phraseText'] = phraseText;
    }

    return map;
  }

  @override
  String toString() {
    return 'WordTracker(wordID: $id, firstUtterance: $firstUtterance, language: $language, note: $note, videoId: $videoId, phraseId: $phraseId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WordTracker) return false;

    return other.id == id &&
        other.firstUtterance == firstUtterance &&
        other.language == language &&
        other.note == note &&
        other.videoId == videoId &&
        other.phraseId == phraseId &&
        other.phraseText == phraseText;
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        firstUtterance,
        language,
        note,
        videoId,
        phraseId,
        phraseText,
      ]);
}

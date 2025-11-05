import 'dart:convert';

import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/time_utils.dart';

class PhraseTracker {
  static const collectionName = 'PhraseTracker';

  PhraseTracker({
    required this.id,
    required this.childId,
    required this.phrase,
    required this.words,
    required this.createdAt,
    required this.needsProcessing,
    required this.language,
    this.note,
    this.videoId,
  });

  final String id;
  final String childId;
  final String phrase;
  final List<String> words;
  final DateTime createdAt;
  final bool needsProcessing;
  final LanguageCode language;
  final String? note;
  final String? videoId;

  PhraseTracker copyWith({
    String? id,
    String? childId,
    String? phrase,
    List<String>? words,
    DateTime? createdAt,
    bool? needsProcessing,
    LanguageCode? language,
    String? note,
    String? videoId,
  }) {
    return PhraseTracker(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      phrase: phrase ?? this.phrase,
      words: words ?? this.words,
      createdAt: createdAt ?? this.createdAt,
      needsProcessing: needsProcessing ?? this.needsProcessing,
      language: language ?? this.language,
      note: note ?? this.note,
      videoId: videoId ?? this.videoId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phrase': phrase,
      'words': words,
      'createdAt': createdAt,
      'needsProcessing': needsProcessing,
      'language': language.name,
      if (note != null && note!.isNotEmpty) 'note': note,
      if (videoId != null && videoId!.isNotEmpty) 'videoId': videoId,
    };
  }

  static PhraseTracker fromMap(
    Map<String, dynamic> map, {
    required String documentId,
    required String childId,
  }) {
    return PhraseTracker(
      id: documentId,
      childId: childId,
      phrase: map['phrase'] as String? ?? documentId,
      words: (map['words'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      createdAt: map['createdAt'] != null
          ? convertToDateTime(map['createdAt'])
          : DateTime.fromMillisecondsSinceEpoch(0),
      needsProcessing: map['needsProcessing'] as bool? ?? false,
      language: LanguageCodeExtension.fromString(
        map['language'] as String? ?? '',
      ),
      note: map['note'] as String?,
      videoId: map['videoId'] as String?,
    );
  }

  static PhraseTracker fromDataWithId(
    DataWithId source, {
    required String childId,
  }) {
    return fromMap(source.data, documentId: source.id, childId: childId);
  }

  String toJson() => jsonEncode(toMap());

  @override
  String toString() {
    return 'PhraseTracker(id: $id, phrase: $phrase, language: $language, needsProcessing: $needsProcessing)';
  }
}

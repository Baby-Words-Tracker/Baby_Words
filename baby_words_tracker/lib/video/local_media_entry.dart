import 'dart:convert';

/// Metadata about a locally stored media file (video or image) that is associated with a parent's child word.
class LocalMediaEntry {
  LocalMediaEntry({
    required this.parentId,
    required this.childId,
    required this.wordId,
    required this.filePath,
    required this.savedAt,
  });

  final String parentId;
  final String childId;
  final String wordId;
  final String filePath;
  final DateTime savedAt;

  String get key => composeKey(parentId, childId, wordId);

  LocalMediaEntry copyWith({
    String? parentId,
    String? childId,
    String? wordId,
    String? filePath,
    DateTime? savedAt,
  }) {
    return LocalMediaEntry(
      parentId: parentId ?? this.parentId,
      childId: childId ?? this.childId,
      wordId: wordId ?? this.wordId,
      filePath: filePath ?? this.filePath,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parentId': parentId,
      'childId': childId,
      'wordId': wordId,
      'filePath': filePath,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  static LocalMediaEntry fromJson(Map<String, dynamic> json) {
    return LocalMediaEntry(
      parentId: json['parentId'] as String,
      childId: json['childId'] as String,
      wordId: json['wordId'] as String,
      filePath: json['filePath'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  static String composeKey(String parentId, String childId, String wordId) {
    return base64Url.encode(
      utf8.encode('$parentId::$childId::$wordId'),
    );
  }
}

import 'dart:convert';

import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:baby_words_tracker/util/time_utils.dart';
import 'package:collection/collection.dart';

class WordLanguageDetail {
  WordLanguageDetail({
    this.lemma,
    this.primaryPartOfSpeech,
    List<String>? allPOS,
    this.primaryCategory,
    List<String>? allCategories,
    this.requestedAt,
    this.updatedAt,
  })  : allPOS = List.unmodifiable(allPOS ?? const []),
        allCategories = List.unmodifiable(allCategories ?? const []);

  final String? lemma;
  final String? primaryPartOfSpeech;
  final List<String> allPOS;
  final String? primaryCategory;
  final List<String> allCategories;
  final DateTime? requestedAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'allPOS': allPOS,
      'allCategories': allCategories,
    };
    if (lemma != null) map['lemma'] = lemma;
    if (primaryPartOfSpeech != null) {
      map['primaryPartOfSpeech'] = primaryPartOfSpeech;
    }
    if (primaryCategory != null) map['primaryCategory'] = primaryCategory;
    if (requestedAt != null) map['requestedAt'] = requestedAt;
    if (updatedAt != null) map['updatedAt'] = updatedAt;
    return map;
  }

  factory WordLanguageDetail.fromMap(Map<String, dynamic> map) {
    return WordLanguageDetail(
      lemma: map['lemma'] as String?,
      primaryPartOfSpeech: map['primaryPartOfSpeech'] as String?,
      allPOS: (map['allPOS'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      primaryCategory: map['primaryCategory'] as String?,
      allCategories: (map['allCategories'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      requestedAt: map['requestedAt'] != null
          ? convertToDateTime(map['requestedAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? convertToDateTime(map['updatedAt'])
          : null,
    );
  }

  WordLanguageDetail copyWith({
    String? lemma,
    String? primaryPartOfSpeech,
    List<String>? allPOS,
    String? primaryCategory,
    List<String>? allCategories,
    DateTime? requestedAt,
    DateTime? updatedAt,
  }) {
    return WordLanguageDetail(
      lemma: lemma ?? this.lemma,
      primaryPartOfSpeech:
          primaryPartOfSpeech ?? this.primaryPartOfSpeech,
      allPOS: allPOS ?? this.allPOS,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      allCategories: allCategories ?? this.allCategories,
      requestedAt: requestedAt ?? this.requestedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'WordLanguageDetail(lemma: $lemma, primaryPOS: $primaryPartOfSpeech, allPOS: $allPOS, primaryCategory: $primaryCategory, allCategories: $allCategories)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WordLanguageDetail) return false;

    return other.lemma == lemma &&
        other.primaryPartOfSpeech == primaryPartOfSpeech &&
        const DeepCollectionEquality().equals(other.allPOS, allPOS) &&
        other.primaryCategory == primaryCategory &&
        const DeepCollectionEquality()
            .equals(other.allCategories, allCategories) &&
        other.requestedAt == requestedAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hashAll([
        lemma,
        primaryPartOfSpeech,
        const DeepCollectionEquality().hash(allPOS),
        primaryCategory,
        const DeepCollectionEquality().hash(allCategories),
        requestedAt,
        updatedAt,
      ]);
}

class Word {
  static String collectionName = 'Word';

  final String word;
  final Set<LanguageCode> languageCodes;
  final Map<LanguageCode, WordLanguageDetail> languageDetails;
  final bool needsProcessing;
  final Set<LanguageCode> languagesProcessed;
  final Set<LanguageCode> languagesPending;
  final LanguageCode? processingLanguage;

  Word({
    required this.word,
    Set<LanguageCode>? languageCodes,
    Map<LanguageCode, WordLanguageDetail>? languageDetails,
    Map<LanguageCode, PartOfSpeech>? partOfSpeech,
    Map<LanguageCode, String>? lemma,
    Map<LanguageCode, String>? category,
    this.needsProcessing = false,
    Set<LanguageCode>? languagesProcessed,
    Set<LanguageCode>? languagesPending,
    this.processingLanguage,
  })  : languageDetails = Map.unmodifiable(
          languageDetails ??
              _buildDetailsFromLegacy(
                partOfSpeech: partOfSpeech,
                lemma: lemma,
                category: category,
              ),
        ),
        languageCodes = Set.unmodifiable(
          _deriveLanguageCodes(
            explicitCodes: languageCodes,
            languageDetails: languageDetails,
            partOfSpeech: partOfSpeech,
            lemma: lemma,
            category: category,
          ),
        ),
        languagesProcessed =
            Set.unmodifiable(languagesProcessed ?? <LanguageCode>{}),
        languagesPending =
            Set.unmodifiable(languagesPending ?? <LanguageCode>{});

  Map<LanguageCode, PartOfSpeech> get partOfSpeech {
    final result = <LanguageCode, PartOfSpeech>{};
    for (final entry in languageDetails.entries) {
      final value = entry.value.primaryPartOfSpeech;
      if (value != null) {
        result[entry.key] = PartofspeechExtension.fromString(value);
      }
    }
    return result;
  }

  Map<LanguageCode, String> get lemma {
    final result = <LanguageCode, String>{};
    for (final entry in languageDetails.entries) {
      final value = entry.value.lemma;
      if (value != null) {
        result[entry.key] = value;
      }
    }
    return result;
  }

  Map<LanguageCode, String> get category {
    final result = <LanguageCode, String>{};
    for (final entry in languageDetails.entries) {
      final value = entry.value.primaryCategory;
      if (value != null) {
        result[entry.key] = value;
      }
    }
    return result;
  }

  Word copyWith({
    String? word,
    Set<LanguageCode>? languageCodes,
    Map<LanguageCode, WordLanguageDetail>? languageDetails,
    bool? needsProcessing,
    Set<LanguageCode>? languagesProcessed,
    Set<LanguageCode>? languagesPending,
    LanguageCode? processingLanguage,
  }) {
    return Word(
      word: word ?? this.word,
      languageCodes: languageCodes ?? this.languageCodes,
      languageDetails: languageDetails ?? this.languageDetails,
      needsProcessing: needsProcessing ?? this.needsProcessing,
      languagesProcessed: languagesProcessed ?? this.languagesProcessed,
      languagesPending: languagesPending ?? this.languagesPending,
      processingLanguage: processingLanguage ?? this.processingLanguage,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'word': word,
      'languageCodes': languageCodes.map((code) => code.name).toList(),
      'needsProcessing': needsProcessing,
      'languagesProcessed':
          languagesProcessed.map((code) => code.name).toList(),
      'languagesPending':
          languagesPending.map((code) => code.name).toList(),
      if (processingLanguage != null) 'language': processingLanguage!.name,
      'languageDetails': languageDetails.map(
        (lang, detail) => MapEntry(lang.name, detail.toMap()),
      ),
    };
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    final languageDetails = _extractLanguageDetails(map);

    final languageCodes = (map['languageCodes'] as List<dynamic>?)
            ?.whereType<String>()
            .map(LanguageCodeExtension.fromString)
            .toSet() ??
        languageDetails.keys.toSet();

    final idValue = map['id'] ?? map['word'];
    if (idValue is! String) {
      throw ArgumentError('Word map must contain an id or word field.');
    }

    return Word(
      word: idValue,
      languageCodes: languageCodes,
      languageDetails: languageDetails,
      needsProcessing: map['needsProcessing'] as bool? ?? false,
      languagesProcessed: (map['languagesProcessed'] as List<dynamic>?)
              ?.whereType<String>()
              .map(LanguageCodeExtension.fromString)
              .toSet() ??
          <LanguageCode>{},
      languagesPending: (map['languagesPending'] as List<dynamic>?)
              ?.whereType<String>()
              .map(LanguageCodeExtension.fromString)
              .toSet() ??
          <LanguageCode>{},
      processingLanguage: map['language'] is String
          ? LanguageCodeExtension.fromString(map['language'] as String)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Word.fromJson(String source) =>
      Word.fromMap(json.decode(source) as Map<String, dynamic>);

  factory Word.fromDataWithId(DataWithId source) {
    final data = Map<String, dynamic>.from(source.data);
    data['id'] = source.id;
    return Word.fromMap(data);
  }

  static Map<String, dynamic> createUpdateMap({
    Set<LanguageCode>? languageCodes,
    bool? needsProcessing,
    Set<LanguageCode>? languagesProcessed,
    Set<LanguageCode>? languagesPending,
    LanguageCode? processingLanguage,
    Map<LanguageCode, WordLanguageDetail>? languageDetails,
  }) {
    final map = <String, dynamic>{};

    if (languageCodes != null) {
      map['languageCodes'] = languageCodes.map((code) => code.name).toList();
    }
    if (needsProcessing != null) {
      map['needsProcessing'] = needsProcessing;
    }
    if (languagesProcessed != null) {
      map['languagesProcessed'] =
          languagesProcessed.map((code) => code.name).toList();
    }
    if (languagesPending != null) {
      map['languagesPending'] =
          languagesPending.map((code) => code.name).toList();
    }
    if (processingLanguage != null) {
      map['language'] = processingLanguage.name;
    }
    if (languageDetails != null) {
      map['languageDetails'] = languageDetails.map(
        (lang, detail) => MapEntry(lang.name, detail.toMap()),
      );
    }

    return map;
  }

  bool isProcessedFor(LanguageCode language) {
    if (languagesProcessed.contains(language)) return true;
    final detail = languageDetails[language];
    return detail?.primaryPartOfSpeech != null;
  }

  WordLanguageDetail? detailForLanguage(LanguageCode language) {
    return languageDetails[language];
  }

  @override
  String toString() {
    return 'Word(word: $word, languageCodes: $languageCodes, languageDetails: $languageDetails, needsProcessing: $needsProcessing)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Word) return false;

    return other.word == word &&
        const DeepCollectionEquality().equals(
            other.languageCodes, languageCodes) &&
        const DeepCollectionEquality().equals(
            other.languageDetails, languageDetails) &&
        other.needsProcessing == needsProcessing &&
        const DeepCollectionEquality().equals(
            other.languagesProcessed, languagesProcessed) &&
        const DeepCollectionEquality().equals(
            other.languagesPending, languagesPending) &&
        other.processingLanguage == processingLanguage;
  }

  @override
  int get hashCode => Object.hashAll([
        word,
        const DeepCollectionEquality().hash(languageCodes),
        const DeepCollectionEquality().hash(languageDetails),
        needsProcessing,
        const DeepCollectionEquality().hash(languagesProcessed),
        const DeepCollectionEquality().hash(languagesPending),
        processingLanguage,
      ]);

  static Map<LanguageCode, WordLanguageDetail> _extractLanguageDetails(
      Map<String, dynamic> map) {
    final details = <LanguageCode, WordLanguageDetail>{};
    final raw = map['languageDetails'];
    if (raw is Map<String, dynamic>) {
      raw.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final code = LanguageCodeExtension.fromString(key);
          details[code] = WordLanguageDetail.fromMap(value);
        }
      });
    }

    if (details.isNotEmpty) {
      return details;
    }

    // Fallback for legacy documents.
    final legacyPartOfSpeech = _mapLegacyPartOfSpeech(map['partOfSpeech']);
    final legacyLemma = _mapLegacyString(map['lemma']);
    final legacyCategory = _mapLegacyString(map['category']);
    return _buildDetailsFromLegacy(
      partOfSpeech: legacyPartOfSpeech,
      lemma: legacyLemma,
      category: legacyCategory,
    );
  }

  static Map<LanguageCode, PartOfSpeech> _mapLegacyPartOfSpeech(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw.map((key, value) => MapEntry(
            LanguageCodeExtension.fromString(key),
            PartofspeechExtension.fromString(value as String),
          ));
    }
    return {};
  }

  static Map<LanguageCode, String> _mapLegacyString(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw.map((key, value) => MapEntry(
            LanguageCodeExtension.fromString(key),
            value as String,
          ));
    }
    return {};
  }

  static Map<LanguageCode, WordLanguageDetail> _buildDetailsFromLegacy({
    Map<LanguageCode, PartOfSpeech>? partOfSpeech,
    Map<LanguageCode, String>? lemma,
    Map<LanguageCode, String>? category,
  }) {
    final languages = {
      ...?partOfSpeech?.keys,
      ...?lemma?.keys,
      ...?category?.keys,
    };

    final details = <LanguageCode, WordLanguageDetail>{};
    for (final language in languages) {
      final pos = partOfSpeech?[language];
      final detail = WordLanguageDetail(
        lemma: lemma?[language],
        primaryPartOfSpeech: pos != null ? pos.name.toUpperCase() : null,
        allPOS: pos != null ? [pos.name.toUpperCase()] : const [],
        primaryCategory: category?[language],
        allCategories:
            category?[language] != null ? [category![language]!] : const [],
      );
      details[language] = detail;
    }
    return details;
  }

  static Set<LanguageCode> _deriveLanguageCodes({
    Set<LanguageCode>? explicitCodes,
    Map<LanguageCode, WordLanguageDetail>? languageDetails,
    Map<LanguageCode, PartOfSpeech>? partOfSpeech,
    Map<LanguageCode, String>? lemma,
    Map<LanguageCode, String>? category,
  }) {
    if (explicitCodes != null && explicitCodes.isNotEmpty) {
      return explicitCodes;
    }

    final codes = <LanguageCode>{};
    if (languageDetails != null) {
      codes.addAll(languageDetails.keys);
    }
    if (partOfSpeech != null) {
      codes.addAll(partOfSpeech.keys);
    }
    if (lemma != null) {
      codes.addAll(lemma.keys);
    }
    if (category != null) {
      codes.addAll(category.keys);
    }
    return codes;
  }
}

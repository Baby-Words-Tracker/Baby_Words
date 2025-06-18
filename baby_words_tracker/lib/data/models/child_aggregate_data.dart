// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:baby_words_tracker/util/time_utils.dart';
import 'package:collection/collection.dart';

class ChildAggregateData {
  static const String collectionName = 'ChildAggregateData';

  /// max number of days to track words learned per day (about 1 month)
  static const int maxWordsPerDayEntries = 35;

  /// max number of weeks to track words learned per week (about 3 months or one quarter)
  static const int maxWordsPerWeekEntries = 12;

  /// max number of months to track words learned per month (about 1 year)
  static const int maxWordsPerMonthEntries = 12;

  /// max number of years to track words learned per year (about 5 years)
  static const int maxWordsPerYearEntries = 5;

  /// the document ID is optional, as it may not be known when creating a new instance
  final String? id;

  // these track the number of words learned per day, week, month, and year
  final Map<DateTime, int> wordsLearnedPerDay;
  final Map<DateTime, int> wordsLearnedPerWeek;
  final Map<DateTime, int> wordsLearnedPerMonth;
  final Map<int, int> wordsLearnedPerYear;

  final Map<PartOfSpeech, int> wordsLearnedPerPartOfSpeech;
  final Map<LanguageCode, int> wordsLearnedPerLanguage;

  // derived stats that are calculated from the above data
  int? wordsLearnedToday;
  int? wordsLearnedThisWeek;
  int? wordsLearnedThisMonth;
  ChildAggregateData({
    this.id,
    required this.wordsLearnedPerDay,
    required this.wordsLearnedPerWeek,
    required this.wordsLearnedPerMonth,
    required this.wordsLearnedPerYear,
    required this.wordsLearnedPerPartOfSpeech,
    required this.wordsLearnedPerLanguage,
    this.wordsLearnedToday,
    this.wordsLearnedThisWeek,
    this.wordsLearnedThisMonth,
  });

  ChildAggregateData copyWith({
    String? id,
    Map<DateTime, int>? wordsLearnedPerDay,
    Map<DateTime, int>? wordsLearnedPerWeek,
    Map<DateTime, int>? wordsLearnedPerMonth,
    Map<DateTime, int>? wordsLearnedPerYear,
    Map<PartOfSpeech, int>? wordsLearnedPerPartOfSpeech,
    Map<LanguageCode, int>? wordsLearnedPerLanguage,
    int? wordsLearnedToday,
    int? wordsLearnedThisWeek,
    int? wordsLearnedThisMonth,
  }) {
    return ChildAggregateData(
      id: id ?? this.id,
      wordsLearnedPerDay: wordsLearnedPerDay ?? this.wordsLearnedPerDay,
      wordsLearnedPerWeek: wordsLearnedPerWeek ?? this.wordsLearnedPerWeek,
      wordsLearnedPerMonth: wordsLearnedPerMonth ?? this.wordsLearnedPerMonth,
      wordsLearnedPerYear: wordsLearnedPerYear ?? this.wordsLearnedPerYear,
      wordsLearnedPerPartOfSpeech:
          wordsLearnedPerPartOfSpeech ?? this.wordsLearnedPerPartOfSpeech,
      wordsLearnedPerLanguage:
          wordsLearnedPerLanguage ?? this.wordsLearnedPerLanguage,
      wordsLearnedToday: wordsLearnedToday ?? this.wordsLearnedToday,
      wordsLearnedThisWeek: wordsLearnedThisWeek ?? this.wordsLearnedThisWeek,
      wordsLearnedThisMonth:
          wordsLearnedThisMonth ?? this.wordsLearnedThisMonth,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'wordsLearnedPerDay': wordsLearnedPerDay,
      'wordsLearnedPerWeek': wordsLearnedPerWeek,
      'wordsLearnedPerMonth': wordsLearnedPerMonth,
      'wordsLearnedPerYear': wordsLearnedPerYear,
      'wordsLearnedPerPartOfSpeech': wordsLearnedPerPartOfSpeech.map(
        (posKey, value) => MapEntry(
          posKey.name,
          value,
        ),
      ),
      'wordsLearnedPerLanguage': wordsLearnedPerLanguage.map(
        (langCodeKey, value) => MapEntry(
          langCodeKey.name,
          value,
        ),
      ),
    };
  }

  /// Converts a map with dynamic (we expect these to be firstore TimeStamp objects but they may be other later or null) keys to a map with DtateTime keys.
  static Map<DateTime, int> _mapDateTimeIntFromMap(Map<dynamic, int>? map) {
    if (map == null) {
      return {};
    }
    return map.map(
      (key, value) => MapEntry(
        convertToDateTime(key) ?? DateTime(1970, 1, 1),
        value,
      ),
    );
  }

  factory ChildAggregateData.fromMap(Map<String, dynamic> map) {
    return ChildAggregateData(
      id: map['id'] as String?,
      wordsLearnedPerDay: _mapDateTimeIntFromMap(
          (map['wordsLearnedPerDay'] as Map<dynamic, int>?)),
      wordsLearnedPerWeek: _mapDateTimeIntFromMap(
          (map['wordsLearnedPerWeek'] as Map<DateTime, int>?)),
      wordsLearnedPerMonth: _mapDateTimeIntFromMap(
          (map['wordsLearnedPerMonth'] as Map<DateTime, int>?)),
      wordsLearnedPerYear: _mapDateTimeIntFromMap(
          (map['wordsLearnedPerYear'] as Map<DateTime, int>?)),
      wordsLearnedPerPartOfSpeech:
          (map['wordsLearnedPerPartOfSpeech'] as Map<String, int>?)?.map(
                  (key, value) =>
                      MapEntry(PartOfSpeechExtension.fromString(key), value)) ??
              {},
      wordsLearnedPerLanguage: ((map['wordsLearnedPerLanguage']
                  as Map<LanguageCode, int>) as Map<String, int>?)
              ?.map((key, value) =>
                  MapEntry(LanguageCodeExtension.fromString(key), value)) ??
          {},
    );
  }

  String toJson() => json.encode(toMap());

  factory ChildAggregateData.fromJson(String source) =>
      ChildAggregateData.fromMap(json.decode(source) as Map<String, dynamic>);

  factory ChildAggregateData.fromDataWithId(
    DataWithId source,
  ) {
    Map<String, dynamic> data = source.data;
    data['id'] = source.id;
    return ChildAggregateData.fromMap(data);
  }

  static Map<String, dynamic> createUpdateMap({
    String? id,
    Map<DateTime, int>? wordsLearnedPerDay,
    Map<DateTime, int>? wordsLearnedPerWeek,
    Map<DateTime, int>? wordsLearnedPerMonth,
    Map<DateTime, int>? wordsLearnedPerYear,
    Map<PartOfSpeech, int>? wordsLearnedPerPartOfSpeech,
    Map<LanguageCode, int>? wordsLearnedPerLanguage,
  }) {
    Map<String, dynamic> updateMap = {};

    if (id != null) updateMap['id'] = id;
    if (wordsLearnedPerDay != null) {
      updateMap['wordsLearnedPerDay'] = wordsLearnedPerDay;
    }
    if (wordsLearnedPerWeek != null) {
      updateMap['wordsLearnedPerWeek'] = wordsLearnedPerWeek;
    }
    if (wordsLearnedPerMonth != null) {
      updateMap['wordsLearnedPerMonth'] = wordsLearnedPerMonth;
    }
    if (wordsLearnedPerYear != null) {
      updateMap['wordsLearnedPerYear'] = wordsLearnedPerYear;
    }
    if (wordsLearnedPerPartOfSpeech != null) {
      updateMap['wordsLearnedPerPartOfSpeech'] = wordsLearnedPerPartOfSpeech
          .map((posKey, value) => MapEntry(posKey.name, value));
    }
    if (wordsLearnedPerLanguage != null) {
      updateMap['wordsLearnedPerLanguage'] = wordsLearnedPerLanguage
          .map((langCodeKey, value) => MapEntry(langCodeKey.name, value));
    }

    return updateMap;
  }

  @override
  String toString() {
    return 'ChildAggregateData(id: $id, wordsLearnedPerDay: $wordsLearnedPerDay, wordsLearnedPerWeek: $wordsLearnedPerWeek, wordsLearnedPerMonth: $wordsLearnedPerMonth, wordsLearnedPerYear: $wordsLearnedPerYear, wordsLearnedPerPartOfSpeech: $wordsLearnedPerPartOfSpeech, wordsLearnedPerLanguage: $wordsLearnedPerLanguage, wordsLearnedToday: $wordsLearnedToday, wordsLearnedThisWeek: $wordsLearnedThisWeek, wordsLearnedThisMonth: $wordsLearnedThisMonth)';
  }

  @override
  bool operator ==(covariant ChildAggregateData other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other.id == id &&
        mapEquals(other.wordsLearnedPerDay, wordsLearnedPerDay) &&
        mapEquals(other.wordsLearnedPerWeek, wordsLearnedPerWeek) &&
        mapEquals(other.wordsLearnedPerMonth, wordsLearnedPerMonth) &&
        mapEquals(other.wordsLearnedPerYear, wordsLearnedPerYear) &&
        mapEquals(
            other.wordsLearnedPerPartOfSpeech, wordsLearnedPerPartOfSpeech) &&
        mapEquals(other.wordsLearnedPerLanguage, wordsLearnedPerLanguage) &&
        other.wordsLearnedToday == wordsLearnedToday &&
        other.wordsLearnedThisWeek == wordsLearnedThisWeek &&
        other.wordsLearnedThisMonth == wordsLearnedThisMonth;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      const DeepCollectionEquality().hash(wordsLearnedPerDay),
      const DeepCollectionEquality().hash(wordsLearnedPerWeek),
      const DeepCollectionEquality().hash(wordsLearnedPerMonth),
      const DeepCollectionEquality().hash(wordsLearnedPerYear),
      const DeepCollectionEquality().hash(wordsLearnedPerPartOfSpeech),
      const DeepCollectionEquality().hash(wordsLearnedPerLanguage),
      wordsLearnedToday,
      wordsLearnedThisWeek,
      wordsLearnedThisMonth,
    ]);
  }

  int get wordsLearnedToday {
    if (wordsLearnedPerDay.isEmpty) return 0;
    DateTime today = DateTime.now().;
    return wordsLearnedPerDay[today] ?? 0;
  }
}

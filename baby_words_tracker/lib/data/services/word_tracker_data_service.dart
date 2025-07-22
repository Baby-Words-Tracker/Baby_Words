import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:flutter/foundation.dart';

class WordTrackerDataService {
  final FirestoreRepository _firestoreRepository;

  WordTrackerDataService(this._firestoreRepository);

  String _childCollectionName(bool useDemoCollection) {
    return useDemoCollection
        ? "demo_${Child.collectionName}"
        : Child.collectionName;
  }

  Future<WordTracker?> createWordTracker(
    String childId,
    String word,
    WordTracker tracker,
    bool isDemoType,
  ) async {
    if (tracker.id == null) {
      debugPrint("Error: tracker ID is null");
      return null;
    }

    final bool result = await _firestoreRepository.addOrUpdateWordTracker(
      _childCollectionName(isDemoType),
      childId,
      WordTracker.collectionName,
      tracker.id!,
      tracker,
    );

    if (!result) {
      debugPrint("Error: failed to create word tracker for ${tracker.id}");
      return null;
    }

    return tracker;
  }

  Future<bool> updateWordTracker(
    String childId,
    String wordID,
    bool isDemoType, {
    DateTime? firstUtterance,
    String? videoID,
  }) async {
    final updateMap = WordTracker.createUpdateMap(
      firstUtterance: firstUtterance,
      videoID: videoID,
    );

    final bool result = await _firestoreRepository.updateSubcollectionDocument(
        _childCollectionName(isDemoType),
        childId,
        WordTracker.collectionName,
        wordID,
        updateMap);

    if (!result) {
      debugPrint("Error: failed to update word tracker for $wordID");
      return false;
    }

    return true;
  }

  Future<bool> addOrUpdateWordTracker(
    String childId,
    String wordId,
    WordTracker wordTracker,
    bool isDemoType,
  ) async {
    final bool sucess = await _firestoreRepository.addOrUpdateWordTracker(
      _childCollectionName(isDemoType),
      childId,
      WordTracker.collectionName,
      wordId,
      wordTracker,
    );

    if (!sucess) {
      debugPrint("Error: failed to add or update word tracker for $wordId");
    }

    return sucess;
  }

  Future<WordTracker?> getWordTracker(
    String childId,
    String id,
    bool isDemoType,
  ) async {
    final word = await _firestoreRepository.readSubcollection(
        _childCollectionName(isDemoType),
        childId,
        WordTracker.collectionName,
        id);
    if (word == null) return null;
    return WordTracker.fromDataWithId(word);
  }

  Future<List<WordTracker>> getWordsFromTime(
    String childId,
    DateTime time,
    bool isDemoType,
  ) async {
    final List<DataWithId> data =
        await _firestoreRepository.subFieldGreaterThan(
            _childCollectionName(isDemoType),
            childId,
            WordTracker.collectionName,
            "firstUtterance",
            time);

    List<WordTracker> words = List.empty(growable: true);
    for (DataWithId word in data) {
      words.add(WordTracker.fromDataWithId(word));
    }

    return words;
  }

  Future<List<WordTracker>> getWordsFromDate(
    String childId,
    DateTime date,
    bool isDemoType,
  ) async {
    // Calculate start and end of the day for the given date
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    final List<DataWithId> data =
        await _firestoreRepository.subQueryByDateRange(
      _childCollectionName(isDemoType),
      childId,
      WordTracker.collectionName,
      "firstUtterance",
      startOfDay,
      endOfDay,
    );

    List<WordTracker> words =
        data.map((word) => WordTracker.fromDataWithId(word)).toList();

    return words;
  }

  Future<List<WordTracker>> getWordsFromDateRange(
    String childId,
    DateTime date,
    int range,
    bool isDemoType,
  ) async {
    // Calculate start and end of the day for the given date
    DateTime startOfDateRange = DateTime(date.year, date.month, date.day);
    DateTime endOfDateRange = startOfDateRange
        .add(Duration(days: range))
        .subtract(const Duration(seconds: 1));

    final List<DataWithId> data =
        await _firestoreRepository.subQueryByDateRange(
      _childCollectionName(isDemoType),
      childId,
      WordTracker.collectionName,
      "firstUtterance",
      startOfDateRange,
      endOfDateRange,
    );

    List<WordTracker> words =
        data.map((word) => WordTracker.fromDataWithId(word)).toList();

    return words;
  }
}

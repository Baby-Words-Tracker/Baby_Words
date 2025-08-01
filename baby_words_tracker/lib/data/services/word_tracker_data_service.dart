import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:flutter/foundation.dart';

class WordTrackerDataService {
  final FirestoreRepository _firestoreRepository;

  WordTrackerDataService(this._firestoreRepository);

  Future<WordTracker?> createWordTracker(
    String childId,
    String word,
    WordTracker tracker,
    bool useDemoCollection,
  ) async {
    if (tracker.id == null) {
      debugPrint("Error: tracker ID is null");
      return null;
    }

    final bool result = await _firestoreRepository.addOrUpdateWordTracker(
      Child.collectionName.demoAwareCollectionName(useDemoCollection),
      childId,
      WordTracker.collectionName.demoAwareCollectionName(useDemoCollection),
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
    bool useDemoCollection, {
    DateTime? firstUtterance,
    String? videoID,
  }) async {
    final updateMap = WordTracker.createUpdateMap(
      firstUtterance: firstUtterance,
      videoID: videoID,
    );

    final bool result = await _firestoreRepository.updateSubcollectionDocument(
        Child.collectionName.demoAwareCollectionName(useDemoCollection),
        childId,
        WordTracker.collectionName.demoAwareCollectionName(useDemoCollection),
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
    bool useDemoCollection,
  ) async {
    final bool sucess = await _firestoreRepository.addOrUpdateWordTracker(
      Child.collectionName.demoAwareCollectionName(useDemoCollection),
      childId,
      WordTracker.collectionName.demoAwareCollectionName(useDemoCollection),
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
    bool useDemoCollection,
  ) async {
    final word = await _firestoreRepository.readSubcollection(
        Child.collectionName.demoAwareCollectionName(useDemoCollection),
        childId,
        WordTracker.collectionName.demoAwareCollectionName(useDemoCollection),
        id);
    if (word == null) return null;
    return WordTracker.fromDataWithId(word);
  }

  Future<List<WordTracker>> getWordsFromTime(
    String childId,
    DateTime time,
    bool useDemoCollection,
  ) async {
    final List<DataWithId> data =
        await _firestoreRepository.subFieldGreaterThan(
            Child.collectionName.demoAwareCollectionName(useDemoCollection),
            childId,
            WordTracker.collectionName
                .demoAwareCollectionName(useDemoCollection),
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
    bool useDemoCollection,
  ) async {
    // Calculate start and end of the day for the given date
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    final List<DataWithId> data =
        await _firestoreRepository.subQueryByDateRange(
      Child.collectionName.demoAwareCollectionName(useDemoCollection),
      childId,
      WordTracker.collectionName.demoAwareCollectionName(useDemoCollection),
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
    bool useDemoCollection,
  ) async {
    // Calculate start and end of the day for the given date
    DateTime startOfDateRange = DateTime(date.year, date.month, date.day);
    DateTime endOfDateRange = startOfDateRange
        .add(Duration(days: range))
        .subtract(const Duration(seconds: 1));

    final List<DataWithId> data =
        await _firestoreRepository.subQueryByDateRange(
      Child.collectionName.demoAwareCollectionName(useDemoCollection),
      childId,
      WordTracker.collectionName.demoAwareCollectionName(useDemoCollection),
      "firstUtterance",
      startOfDateRange,
      endOfDateRange,
    );

    List<WordTracker> words =
        data.map((word) => WordTracker.fromDataWithId(word)).toList();

    return words;
  }
}

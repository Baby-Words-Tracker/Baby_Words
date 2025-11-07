import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:baby_words_tracker/data/repositories/i_firestore_repository.dart';
import 'package:flutter/foundation.dart';

class WordTrackerDataService {
  final IFirestoreRepository fireRepo;

  WordTrackerDataService({IFirestoreRepository? repository})
      : fireRepo = repository ?? FirestoreRepository();

  Future<WordTracker?> createWordTracker(
    String childId,
    String word,
    WordTracker tracker,
  ) async {
    if (tracker.id == null) {
      debugPrint("Error: tracker ID is null");
      return null;
    }

    final bool result = await fireRepo.addOrUpdateWordTracker(
      Child.collectionName,
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
    String wordID, {
    DateTime? firstUtterance,
  }) async {
    final updateMap = WordTracker.createUpdateMap(
      firstUtterance: firstUtterance,
    );

    final bool result = await fireRepo.updateSubcollectionDocument(
        Child.collectionName,
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
  ) async {
    final bool sucess = await fireRepo.addOrUpdateWordTracker(
      Child.collectionName,
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

  Future<WordTracker?> getWordTracker(String childId, String id) async {
    final word = await fireRepo.readSubcollection(
        Child.collectionName, childId, WordTracker.collectionName, id);
    if (word == null) return null;
    return WordTracker.fromDataWithId(word);
  }

  Future<List<WordTracker>> getWordsFromTime(
      String childId, DateTime time) async {
    // Convert to UTC to avoid DST issues - Firestore stores timestamps in UTC
    final timeUtc = time.toUtc();
    final List<DataWithId> data = await fireRepo.subFieldGreaterThan(
        Child.collectionName,
        childId,
        WordTracker.collectionName,
        "firstUtterance",
        timeUtc);

    List<WordTracker> words = List.empty(growable: true);
    for (DataWithId word in data) {
      words.add(WordTracker.fromDataWithId(word));
    }

    return words;
  }

  Future<List<WordTracker>> getWordsFromDate(
      String childId, DateTime date) async {
    // Calculate start and end of the day for the given date in UTC
    // Use UTC to avoid DST issues - Firestore stores timestamps in UTC
    final dateUtc = date.toUtc();
    DateTime startOfDay = DateTime.utc(dateUtc.year, dateUtc.month, dateUtc.day);
    DateTime endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    final List<DataWithId> data = await fireRepo.subQueryByDateRange("Child",
        childId, "WordTracker", "firstUtterance", startOfDay, endOfDay);

    List<WordTracker> words =
        data.map((word) => WordTracker.fromDataWithId(word)).toList();

    return words;
  }

  Future<List<WordTracker>> getWordsFromDateRange(
      String childId, DateTime date, int range) async {
    // Calculate start and end of the day for the given date in UTC
    // Use UTC to avoid DST issues - Firestore stores timestamps in UTC
    final dateUtc = date.toUtc();
    DateTime startOfDateRange = DateTime.utc(dateUtc.year, dateUtc.month, dateUtc.day);
    DateTime endOfDateRange = startOfDateRange
        .add(Duration(days: range))
        .subtract(const Duration(seconds: 1));

    final List<DataWithId> data = await fireRepo.subQueryByDateRange(
        "Child",
        childId,
        "WordTracker",
        "firstUtterance",
        startOfDateRange,
        endOfDateRange);

    List<WordTracker> words =
        data.map((word) => WordTracker.fromDataWithId(word)).toList();

    return words;
  }

  Future<bool> deleteWordTracker(String childId, String wordId) async {
    final success = await fireRepo.deleteWordTrackerDocument(
      Child.collectionName,
      childId,
      WordTracker.collectionName,
      wordId,
    );
    if (!success) {
      debugPrint("Error: failed to delete word tracker for $wordId");
    }
    return success;
  }
}

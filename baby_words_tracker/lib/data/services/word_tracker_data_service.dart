import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:flutter/foundation.dart';

class WordTrackerDataService  extends ChangeNotifier{

  static final fireRepo = FirestoreRepository();

  Future<WordTracker?> createWordTracker(String childId, String wordID, DateTime firstUtterance, [String? videoID]) async {
    final object = WordTracker(id: wordID, firstUtterance: firstUtterance, videoID: videoID);

    final String? result = await fireRepo.addWordTracker("Child", childId, wordID, object.toMap());
    
    if (result == null) {
      return null;
    }

    notifyListeners();
    return object.copyWith(id: result);
  }

  Future<WordTracker?> getWordTracker(String childId, String id) async {
    final word = await fireRepo.readSubcollection("Child", childId, "Word", id);
    if (word == null) return null;
    return WordTracker.fromDataWithId(word);
  }

  Future<List<WordTracker>> getWordsFromTime(String childId, DateTime time) async {
    final List<DataWithId> data = await fireRepo.subFieldGreaterThan("Child", childId, "WordTracker", "firstUtterance", time);
    
    List<WordTracker> words = List.empty(growable: true);
    for(DataWithId word in data) {
      words.add(WordTracker.fromDataWithId(word));
    }

    return words;
  }

  Future<List<WordTracker>> getWordsFromDate(String childId, DateTime date) async {
  // Calculate start and end of the day for the given date
  DateTime startOfDay = DateTime(date.year, date.month, date.day);
  DateTime endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

  final List<DataWithId> data = await fireRepo.subQueryByDateRange(
    "Child", childId, "WordTracker", "firstUtterance", startOfDay, endOfDay
  );
  
  List<WordTracker> words = data.map((word) => WordTracker.fromDataWithId(word)).toList();
  
  return words;
}

}
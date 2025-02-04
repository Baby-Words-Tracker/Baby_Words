import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/repositories/FirestoreRepository.dart';
import 'package:flutter/foundation.dart';

class WordTrackerDataService  extends ChangeNotifier{

  static final fireRepo = FirestoreRepository();

  Future<WordTracker> createWordTracker(String childId, String wordID, DateTime firstUtterance, [String? videoID]) async {
    final object = WordTracker(id: wordID, firstUtterance: firstUtterance, videoID: videoID);
    fireRepo.incrementField("Child", childId, "wordCount", 1);
    String returnId = await fireRepo.createSubcollectionDocWithId("Child", childId, "WordTracker", wordID, object.toMap());

    notifyListeners();
    return object.copyWith(id: returnId);
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
    final List<DataWithId> data = await fireRepo.subQueryByField("Child", childId, "WordTracker", "firstUtterance", date);
    
    List<WordTracker> words = List.empty(growable: true);
    for(DataWithId word in data) {
      words.add(WordTracker.fromDataWithId(word));
    }

    return words;
  }

}
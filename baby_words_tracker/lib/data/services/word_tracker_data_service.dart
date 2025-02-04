import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/repositories/FirestoreRepository.dart';

class WordTrackerDataService {

  static final fireRepo = FirestoreRepository();

  Future<WordTracker> createWordTracker(String childId, String wordID, DateTime firstUtterance, int numUtterances, [String? videoID]) async {
    final object = WordTracker(id: wordID, firstUtterance: firstUtterance, numUtterances: numUtterances, videoID: videoID);
    fireRepo.incrementField("Child", childId, "wordCount", 1);
    String returnId = await fireRepo.createSubcollectionDocWithId("Child", childId, "WordTracker", wordID, object.toMap());

    return object.copyWith(id: returnId);
  }

  Future<WordTracker> getWordTracker(String childId, String id) async {
    return WordTracker.fromDataWithId(await fireRepo.readSubcollection("Child", childId, "Word", id));
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
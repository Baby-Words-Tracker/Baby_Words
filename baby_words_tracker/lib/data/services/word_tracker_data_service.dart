import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/repositories/FirestoreRepository.dart';

class WordTrackerDataService {

  static final fireRepo = FirestoreRepository();

  Future<String> createWordTracker(String childId, String wordID, DateTime firstUtterance, int numUtterances, [String? videoID]) async {
    final object = WordTracker(id: wordID, firstUtterance: firstUtterance, numUtterances: numUtterances, videoID: videoID);
    fireRepo.incrementField("Child", childId, "wordCount", 1);
    return await fireRepo.createSubcollectionWithId("Child", childId, "WordTracker", wordID, object.toMap());
  }

  Future<WordTracker> getWordTracker(String childId, String id) async {
    return WordTracker.fromMap(await fireRepo.readSubcollection("Child", childId, "Word", id));
  }

  Future<List<WordTracker>> getWordsFromTime(String childId, DateTime time) async {
    final List<DataWithId> data = await fireRepo.subFieldGreaterThan("Child", childId, "WordTracker", "firstUtterance", time);
    
    List<WordTracker> words = List.empty(growable: true);
    for(DataWithId word in data) {
      words.add(WordTracker.fromDataWithId(word));
    }

    return words;
  }

  Future<List<WordTracker>> getWordsFromDate(String childId, DateTime) async {
    List<WordTracker> words = List.empty(growable : true); 
    return words; 
  }

}
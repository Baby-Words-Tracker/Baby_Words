import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/repositories/FirestoreRepository.dart';

class WordTrackerDataService {

  static final fireRepo = FirestoreRepository();

  Future<String> createWordTracker(String childId, String wordID, DateTime firstUtterance, int numUtterances, [String? videoID]) async {
    final object = WordTracker(id: wordID, firstUtterance: firstUtterance, numUtterances: numUtterances, videoID: videoID);
    return await fireRepo.createSubcollectionWithId("Child", childId, "WordTracker", wordID, object.toMap());
  }

  Future<WordTracker> getResearcher(String childId, String id) async {
    return WordTracker.fromMap(await fireRepo.readSubcollection("Child", childId, "Word", id));
  }

}
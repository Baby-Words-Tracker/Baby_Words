import '../repositories/FirestoreRepository.dart';
import '../models/child.dart';
import '../models/parent.dart';
import '../models/researcher.dart';
import '../models/word_tracker.dart';
import '../models/word.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';

/*
set of functions that are allowed to directly access the models and repository
*/
class DataService{

  final FirestoreRepository repo = FirestoreRepository();

  DataService();

  //parent services
  Future<String> createParent(String parEmail, String parName, List<String> parChildIDs ) async {
    final par = Parent(email: parEmail, name : parName, childIDs : parChildIDs); 
    late String returnId; 
    await repo.create("Parent", par.toMap()).then(
      (id) {
        returnId = id;
      }
    );
    return returnId; 
  }

  void addChildToParent(String parentId, String childId) async {
    await repo.appendToArrayField("Parent", parentId, "childIDs", childId);
    await repo.appendToArrayField("Child", childId, "parentIDs", parentId);
  }


  //child services
  Future<String> createChild(DateTime cBirthDay, String cName, int cWordCount, List<String> cParentIDs) async {
    final object = Child(birthday: cBirthDay, name: cName, wordCount: cWordCount, parentIDs: cParentIDs);
    late String returnId;
    await repo.create("Child", object.toMap()).then(
      (id) {
        returnId = id;
      }
    );
    return returnId; 
  }

  //word services
  Future<String> createWord(String word_name, List<LanguageCode> LanguageCodes, PartOfSpeech PartOfSpeech, String Definition) async {
    final object = Word(word: word_name, languageCodes : LanguageCodes, partOfSpeech: PartOfSpeech, definition: Definition);
    late String returnId;
    await repo.createWithId("Word", word_name, object.toMap()).then(
      (id) {
        returnId = id;
      }
    );
    return returnId;
  }

  //word_tracker services
  Future<String> createWordTracker(String childId, String wordID, DateTime firstUtterance, int numUtterances, [String? videoID]) async {
    final object = WordTracker(id: wordID, firstUtterance: firstUtterance, numUtterances: numUtterances, videoID: videoID);
    late String returnId; 
    await repo.createSubcollectionWithId("Child", childId, "WordTracker", wordID, object.toMap()).then(
      (id) {
        returnId = id;
      }
    );
    return returnId;
  }

  //researcher services
  Future<String> addResearcher(String email, String name, String institution, [String? phoneNumber]) async {
    final object = Researcher(email: email, name: name, institution: institution, phoneNumber: phoneNumber);
    late String returnId;
    await repo.create("Researcher", object.toMap()).then(
      (id) {
        returnId = id;
      }
    );
    return returnId;
  }

}
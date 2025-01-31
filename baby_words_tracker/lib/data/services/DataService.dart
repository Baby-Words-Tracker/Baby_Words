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
  String createParent(String parEmail, String parName, List<String> parChildIDs ) {
    final par = Parent(email: parEmail, name : parName, childIDs : parChildIDs); 
    late String returnId; 
    repo.create("Parent", par.toMap()).then(
      (id) {
        returnId = id;
      }
    );
    return returnId; 
  }

  void addChildToParent(String parentId, String childId){
    late Parent parentObject;
    repo.read("Parent", parentId).then(
      (data) {
        parentObject = Parent.fromMap(data);
      }
    );
    parentObject.childIDs.add(childId);

    late Child childObject;
    repo.read("Child", childId).then(
      (data) {
        childObject = Child.fromMap(data);
      }
    );
    childObject.parentIDs.add(parentId);

    repo.update("Parent", parentId, parentObject.toMap());
    repo.update("Child", childId, childObject.toMap());
  }


  //child services
  String createChild(String cid, DateTime cBirthDay, String cName, int cWordCount, List<String> cParentIDs) {
    final object = Child(id : cid, birthday: cBirthDay, name: cName, wordCount: cWordCount, parentIDs: cParentIDs);
    late String returnId;
    repo.create("Child", object.toMap()).then(
      (id) {
        returnId = id;
      }
    );
    return returnId; 
  }

  //word services
  String createWord(String word_name, List<LanguageCode> LanguageCodes, PartOfSpeech PartOfSpeech, String Definition) {
    final object = Word(word: word_name, languageCodes : LanguageCodes, partOfSpeech: PartOfSpeech, definition: Definition);
    late String returnId;
    repo.create("Word", object.toMap()).then(
      (id) {
        returnId = id;
      }
    );
    return returnId;
  }

  //word_tracker services
  //TODO: change to be a subcollection
  String createWordTracker(String childId, String wordID, DateTime firstUtterance, int numUtterances, String videoID) {
    final object = WordTracker(id: wordID, firstUtterance: firstUtterance, numUtterances: numUtterances, videoID: videoID);
    late String returnId; 
    repo.createSubcollection("Child", childId, "WordTracker", object.toMap()).then(
      (id) {
        returnId = id;
      }
    );
    return returnId; 
  }

  //researcher services
  String addResearcher(String researcherID, String email, String name, String institution, String? phoneNumber) {
    final object = Researcher(id: researcherID, email: email, name: name, institution: institution);
    late String returnId;
    repo.create("Researcher", object.toMap()).then(
      (id) {
        returnId = id;
      }
    ); 
    return returnId;
  }

}
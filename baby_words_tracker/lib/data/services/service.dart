import '../repositories/repository.dart';
import '../models/Child.dart';
import '../models/Parent.dart';
import '../models/researcher.dart';
import '../models/word_tracker.dart';
import '../models/word.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';

/*
set of functions that are allowed to directly access the models and repository
*/
class Service{

  final repository repo = repository();

  Service();

  //parent services
  
  Future<String> addParent(String par_id, String parEmail, String parName, List<String> parChildIDs ) {
    final par = Parent(id : par_id, email: parEmail, name : parName, childIDs : parChildIDs); 
    return repo.create("Parent", par.toMap());
  }


  //child services
  Future<String> addChild(String c_id, DateTime cBirthDay, String cName, int cWordCount, List<String> cParentIDs) {
    final object = Child(id : c_id, birthday: cBirthDay, name: cName, wordCount: cWordCount, parentIDs: cParentIDs);
    return repo.create("Child", object.toMap());
  }

  //word services
  Future<String> addWord(String word_name, List<LanguageCode> LanguageCodes, PartOfSpeech PartOfSpeech, String Definition) {
    final object = Word(word: word_name, languageCodes : LanguageCodes, partOfSpeech: PartOfSpeech, definition: Definition);
    return repo.create("Word", object.toMap());

  }

  //word_tracker services
  Future<String> addWordToChild(String wordID, DateTime firstUtterance, int numUtterances, String videoID) {
    final object = Wordtracker(wordID: wordID, firstUtterance: firstUtterance, numUtterances: numUtterances, videoID: videoID);
    return repo.create("WordTracker", object.toMap());
  }

  //researcher services
  Future<String> addResearcher(String researcherID, String email, String name, String institution, String? phoneNumber) {
    final object = Researcher(researcherID: researcherID, email: email, name: name, institution: institution);
    return repo.create("Researcher", object.toMap()); 
  }
}
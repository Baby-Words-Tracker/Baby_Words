import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:flutter/foundation.dart';


class WordDataService extends ChangeNotifier{

  static final fireRepo = FirestoreRepository();

  //word services
  Future<Word?> createWord(String wordName, List<LanguageCode> languageCodes, PartOfSpeech partOfSpeech, String definition) async {
    final object = Word(word: wordName, languageCodes : languageCodes, partOfSpeech: partOfSpeech, definition: definition);
    String? returnId = await fireRepo.createWithId("Word", wordName, object.toMap());

    if (returnId == null) {
      debugPrint("Error: create word failed.");
      return null;
    }

    notifyListeners();
    return object.copyWith(word: returnId);
  }

  Future<Word?> getWord(String id) async {
    final word = await fireRepo.read("Word", id);
    if (word == null) return null;
    
    return Word.fromDataWithId(word);
  }

}
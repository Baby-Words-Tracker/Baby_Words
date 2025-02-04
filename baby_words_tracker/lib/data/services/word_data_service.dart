import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/data/repositories/FirestoreRepository.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:flutter/foundation.dart';


class WordDataService extends ChangeNotifier{

  static final fireRepo = FirestoreRepository();

  //word services
  Future<Word> createWord(String word_name, List<LanguageCode> LanguageCodes, PartOfSpeech PartOfSpeech, String Definition) async {
    final object = Word(word: word_name, languageCodes : LanguageCodes, partOfSpeech: PartOfSpeech, definition: Definition);
    String returnId = await fireRepo.createWithId("Word", word_name, object.toMap());
    notifyListeners();

    return object.copyWith(word: returnId);
  }

  Future<Word> getWord(String id) async {
    //FIXME: really hacky way to handle nullity
    return Word.fromDataWithId(await fireRepo.read("Word", id) ?? DataWithId(id: "", data: {"null" : "data"}));
  }

}
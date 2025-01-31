import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/data/repositories/FirestoreRepository.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';


class WordDataService {

  static final fireRepo = FirestoreRepository();

  //Reseacher services
  //word services
  Future<String> createWord(String word_name, List<LanguageCode> LanguageCodes, PartOfSpeech PartOfSpeech, String Definition) async {
    final object = Word(word: word_name, languageCodes : LanguageCodes, partOfSpeech: PartOfSpeech, definition: Definition);
    return await fireRepo.createWithId("Word", word_name, object.toMap());
  }

  Future<Word> getWord(String id) async {
    return Word.fromMap(await fireRepo.read("Word", id), id);
  }

}
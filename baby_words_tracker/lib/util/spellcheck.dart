import 'package:baby_words_tracker/util/language_code.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/models/word.dart';

//basic spellcheck that checks if a word exists in our word bank or in the englsh dictionary
bool spellcheck(String word, {LanguageCode language = LanguageCode.en}) {
  final word_service = WordDataService();
  late Word? wordTest;

  //check our word bank for word
  word_service.getWord(word).then(
    (test) {
      wordTest = test;
    }
  );
  if(wordTest != null) return true;

  String url = "";
  //check dictionary for word, choose dictionary with switch
  switch (language) {
    case LanguageCode.en:
      url = "https://api.dictionaryapi.dev/api/v2/entries/en/" + word;
      break;
    default:
    return true; //no dictionary for this language, just accept it LMAO
  }
  late http.Response response;
  http.get(Uri.parse(url)).then(
      (getResponse) {
        response = getResponse; 
      }
  );
  if(response.statusCode == 200) return true;

  return false; 
}
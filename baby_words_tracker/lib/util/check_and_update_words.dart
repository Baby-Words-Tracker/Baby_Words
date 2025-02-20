import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/models/word.dart';
import 'dart:convert';

//basic spellcheck that checks if a word exists in our word bank or in the englsh dictionary
Future<bool?> checkAndUpdateWords(String word, {LanguageCode language = LanguageCode.en}) async {
  final word_service = WordDataService();
  Word? wordTest = await word_service.getWord(word); 
  if(wordTest != null) return true;

  String url = "";
  //check dictionary for word, choose dictionary with switch
  switch (language) {
    case LanguageCode.en:
      url = "https://api.dictionaryapi.dev/api/v2/entries/en/$word";
      break;
    default:
    return false; //no dictionary for this language
  }
  final http.Response response = await http.get(Uri.parse(url)); 
  
  if(response.statusCode == 200) {
    final List<dynamic> responseBody = jsonDecode(response.body);

    final Map<String, dynamic> responseMap = responseBody[0];
    
    final Map<String, dynamic> wordData = responseMap['meanings'][0];

    final PartOfSpeech partOfSpeech = PartOfSpeech.values.byName(wordData['partOfSpeech'] as String);
    final String wordResponse = responseMap['word'];
    final wordMeaning = wordData['definitions'][0]['definition']; 

    List<LanguageCode> languages = [language];

    final Word? newWord = await word_service.createWord(wordResponse, languages, partOfSpeech, wordMeaning); 
    if (newWord == null) return null;
    
    return true;
  }

  return false; 
}
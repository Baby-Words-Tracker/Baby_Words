import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/models/word.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

//basic spellcheck that checks if a word exists in our word bank or in the englsh dictionary
Future<bool?> checkAndUpdateWords(String word, {List<LanguageCode> languages = const [LanguageCode.en, LanguageCode.es]}) async {
  final word_service = WordDataService();
  Word? wordTest = await word_service.getWord(word); 
  if(wordTest != null) return true;

  String url = "https://www.wikidata.org/w/api.php?action=wbsearchentities&search=${Uri.encodeComponent(word)}&language=en&type=lexeme&format=json"; //get wikidata pages associated with word (will return pages from all languages that have that word)
  
  final http.Response response = await http.get(Uri.parse(url), headers: {'User-Agent': 'Dart/Flutter'},); 
  
  if(response.statusCode == 200) {
    final Map<String, dynamic> responseBody = jsonDecode(response.body); // get body
    final List<dynamic> searchList = responseBody['search'];

    if (searchList == []) {
      debugPrint("did not find any search results");
      return false;
    }

    for (Map<String, dynamic> item in searchList) {
      final Map<String, dynamic> match = item['match'];
      final List<String> stringLang = languages.map((lang) => lang.displayCode).toList(); 

      if (stringLang.contains(match['language'])) { //this check may or may not work def needs to be tested
        final LanguageCode matchLang = LanguageCode.values.firstWhere(
                                    (lang) => lang.name == match['language'],
                                    orElse: () => throw ArgumentError('Invalid language:' + match['language']), //error should never be reached
                                    );
        final String id = item['id'];
        debugPrint("Current word id: $id");
        final PartOfSpeech partOfSpeech = PartOfSpeech.values.byName(item['description'].split(' ')[1] as String);

        final idUrl = "https://www.wikidata.org/wiki/Special:EntityData/$id.json";
        final http.Response idResponse = await http.get(Uri.parse(idUrl));

        if(idResponse.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(idResponse.body);
          final Map<String, dynamic> entity = body['entities'];
          final Map<String, dynamic> code = entity[id];
          final List<dynamic> senses = code['senses'];
          final Map<String, dynamic> glosses = senses[0]['glosses'];
          final String? definition = glosses['en']?['value'];

          debugPrint("Current definition: $definition"); 

          //if (definition == null) return null;

          List<LanguageCode> language = [matchLang];

          final Word? newWord = await word_service.createWord(word, language, partOfSpeech, definition); 
          if (newWord == null) return null;

          return true;

        }
        return false;
      }
    }
    debugPrint("was unable to match language code: $languages");
    return false;
  }
  else {
      final int status = response.statusCode;
      debugPrint("did not get a response: $status");
  }

  return false; 
}
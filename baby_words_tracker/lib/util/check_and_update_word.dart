import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:http/http.dart' as http;
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/models/word.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class WikiWordData {
  final String word;
  final Set<LanguageCode> languages;
  final Map<LanguageCode, PartOfSpeech> partsOfSpeech;

  WikiWordData(
    this.word, {
    Set<LanguageCode>? languages,
    Map<LanguageCode, PartOfSpeech>? partsOfSpeech,
  })  : languages = languages ?? <LanguageCode>{},
        partsOfSpeech = partsOfSpeech ?? <LanguageCode, PartOfSpeech>{};
}

Future<http.Response> fetchWordData(
  String word, {
  int continueIndex = 0,
  int resultsLimit = 7,
}) async {
  String url =
      "https://www.wikidata.org/w/api.php?action=wbsearchentities&search=${Uri.encodeComponent(word)}&language=en&type=lexeme&format=json&limit=$resultsLimit&origin=*&offset=$continueIndex";

  debugPrint("word: $word");
  debugPrint("url parsed word: ${Uri.encodeComponent(word)}");
  debugPrint("url: $url");
  debugPrint("url encoded: ${Uri.parse(url)}");

  try {
    final response = await http.get(
      Uri.parse(url),
      // TODO: we must include an informative User-Agent header that includes contact information
      //  Wikimedia suggests this format: <client name>/<version> (<contact information>) <library/framework name>/<version> [<library name>/<version> ...]
      //  must include bot in the string if we run an automated agent
      //  see https://foundation.wikimedia.org/wiki/Policy:Wikimedia_Foundation_User-Agent_Policy
      headers: {'User-Agent': 'WordBuds/0.1 Dart/Flutter'},
    );
    return response;
  } catch (e) {
    debugPrint("fetchWordData: ERROR fetching data: $e");
    rethrow;
  }
}

WikiWordData? fromSearchList(
  String word,
  List<dynamic> searchList, {
  Set<LanguageCode> languages = const {
    LanguageCode.en,
    LanguageCode.es,
  },
}) {
  final WikiWordData wordData = WikiWordData(word);

  for (Map<String, dynamic> item in searchList) {
    final String? label = item['label'];
    if (label == null ||
        label.toLowerCase().trim() != word.toLowerCase().trim()) {
      continue;
    }

    final String? languageCodeName = item['match']['language'];
    if (languageCodeName == null) continue;

    final languageCodeEnum = LanguageCodeExtension.fromString(languageCodeName);
    if (!languages.contains(languageCodeEnum)) {
      debugPrint(
          "fromSearchList(): unrecognized language $languageCodeName (were looking for ${languages.map((lang) => lang.name).join(', ')})");
      continue; // skip this item if the language code is not valid
    }

    wordData.languages.add(languageCodeEnum);

    List<String> desc = item['description'].split(", ");
    debugPrint("Description: $desc");

    final String pOSString = desc.isNotEmpty ? desc[1] : "";
    debugPrint("Part of speech string: $pOSString");

    final PartOfSpeech partOfSpeech =
        PartofspeechExtension.fromString(pOSString);
    debugPrint("Matched part of speech: $partOfSpeech");
    if (partOfSpeech == PartOfSpeech.unknown) {
      debugPrint("fromSearchList(): unrecognized part of speech $pOSString");
    }

    wordData.partsOfSpeech[languageCodeEnum] = partOfSpeech;
  }

  if (wordData.partsOfSpeech.isEmpty) {
    debugPrint("fromSearchList(): no parts of speech found for $word");
    return null; // no parts of speech found
  }

  return wordData;
}

Future<String?> getWordDefinition(
  String wikiWordId,
) async {
  final idUrl =
      "https://www.wikidata.org/wiki/Special:EntityData/$wikiWordId.json";
  final http.Response idResponse = await http.get(Uri.parse(idUrl));

  if (idResponse.statusCode == 200) {
    final Map<String, dynamic> body = jsonDecode(idResponse.body);
    final Map<String, dynamic> entity = body['entities'];
    final Map<String, dynamic> code = entity[wikiWordId];
    final List<dynamic> senses = code['senses'];
    final Map<String, dynamic> glosses =
        senses.isNotEmpty ? senses[0]['glosses'] : {};
    final String? definition = glosses['en']?['value'];

    debugPrint("Current definition: $definition");

    //if (definition == null) return null;
    return definition;
  }
  return null;
}

//basic spellcheck that checks if a word exists in our word bank or in the englsh dictionary
Future<bool?> checkAndUpdateWord(
  String word,
  WordDataService wordDataService, {
  Set<LanguageCode> languages = const {
    LanguageCode.en,
    LanguageCode.es,
  },
}) async {
  Word? wordTest = await wordDataService.getWord(word);
  if (wordTest != null /* && wordTest.languageCodes == languages */) {
    return true; //word exists already in our word bank
  }

  final http.Response response = await fetchWordData(word);

  debugPrint("Response status code: ${response.statusCode}");
  debugPrint("Response body: ${response.body}");

  // can check search-continue parameter to see if there are more results
  if (response.statusCode == 200) {
    final Map<String, dynamic> responseBody =
        jsonDecode(response.body); // get body
    final List<dynamic> searchList = responseBody['search'];

    if (searchList.isEmpty) {
      debugPrint("did not find any search results");
      return false;
    }

    final wordData = fromSearchList(
      word,
      searchList,
      languages: languages,
    );

    if (wordData != null) {
      debugPrint(
          "Creating New Word from search list: ${wordData.word}, ${wordData.languages}, ${wordData.partsOfSpeech}");
      final Word? newWord = await wordDataService.createWord(
          word,
          wordData.languages.toList(),
          wordData.partsOfSpeech,
          {for (var lang in wordData.languages) lang: null});

      if (newWord == null) return null;

      return true;
    }

    debugPrint("Could not find word $word with language code: $languages");
    return false;
  } else {
    final int status = response.statusCode;
    debugPrint("did not get a response: $status");
  }

  return false;
}

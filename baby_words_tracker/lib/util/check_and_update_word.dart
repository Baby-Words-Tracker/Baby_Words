import 'package:baby_words_tracker/exceptions/document_creation_failed_exception.dart';
import 'package:baby_words_tracker/exceptions/document_update_failed_exception.dart';
import 'package:baby_words_tracker/exceptions/network_failure_exception.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:flutter/material.dart';
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
  // see: https://www.wikidata.org/w/api.php for help on the API
  String url =
      "https://www.wikidata.org/w/api.php?action=wbsearchentities&search=${Uri.encodeComponent(word)}&language=en&type=lexeme&format=json&limit=$resultsLimit&origin=*&continue=$continueIndex";

  // debugPrint("word: $word");
  // debugPrint("url parsed word: ${Uri.encodeComponent(word)}");
  // debugPrint("url: $url");
  // debugPrint("url encoded: ${Uri.parse(url)}");

  try {
    // we must include an informative User-Agent header that includes contact information
    //  Wikimedia suggests this format: <client name>/<version> (<contact information>) <library/framework name>/<version> [<library name>/<version> ...]
    //  must include bot in the string if we run an automated agent
    //  see https://foundation.wikimedia.org/wiki/Policy:Wikimedia_Foundation_User-Agent_Policy
    // TODO: add a website to the user agent header
    String headerText =
        'WordBuds/0.1 (websitePending; lecslab@ua.edu) Dart/Flutter';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': headerText,
        if (kIsWeb) 'Api-User-Agent': headerText, // for web, use Api-User-Agent
      },
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
  Set<LanguageCode> languagesToRetrieve = const {
    LanguageCode.en,
    LanguageCode.es,
  },
  WikiWordData? existingWordData,
}) {
  // TODO: remove this in production and add a log message
  if (existingWordData != null) {
    assert(
      existingWordData.word == word,
      "Existing word data must match the provided word",
    );
  }
  final WikiWordData wordData = existingWordData ?? WikiWordData(word);

  for (Map<String, dynamic> item in searchList) {
    final String? label = item['label'];
    if (label == null ||
        label.toLowerCase().trim() != word.toLowerCase().trim()) {
      continue;
    }

    final String? languageCodeName = item['match']['language'];
    if (languageCodeName == null) continue;

    final languageCodeEnum = LanguageCodeExtension.fromString(languageCodeName);
    if (!languagesToRetrieve.contains(languageCodeEnum)) {
      debugPrint(
          "fromSearchList(): unrecognized language $languageCodeName (were looking for ${languagesToRetrieve.map((lang) => lang.name).join(', ')})");
      continue; // skip this item if the language code is not valid
    }

    wordData.languages.add(languageCodeEnum);

    List<String> desc = item['description'].split(", ");
    debugPrint("Description: $desc");

    final String pOSString = desc.isNotEmpty ? desc[1] : "";
    debugPrint("Part of speech string: $pOSString");

    final PartOfSpeech partOfSpeech =
        PartOfSpeechExtension.fromString(pOSString);
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

    return definition;
  }
  return null;
}

/// Checks if [word] exists in the word bank for the target language.
/// If it does not exist, it fetches the word data from the Wikidata API,
/// creates a new word in the word bank, and returns true.
/// If it exists but does not have the target language, it updates the word
/// with the new language and returns true.
/// If it exists and has the target language, it returns true.
/// If it exists but does not need processing, it returns true.
/// [word] is the word to check.
/// [wordDataService] is the service to interact with our word data.
/// [targetLanguage] is the language to search for the words data in in the Wikidata database.
/// [languagesToRetrieve] is the set of languages to retrieve data for from the Wikidata API.
///
/// Throws [NetworkFailureException] if the Wikidata Api request fails.
/// Throws [DocumentCreationFailedException] if the word could not be created.
/// Throws [DocumentUpdateFailedException] if the word could not be updated.
Future<bool> checkAndUpdateWord(
  String word,
  WordDataService wordDataService, {
  LanguageCode targetLanguage = LanguageCode.en,
  Set<LanguageCode> languagesToRetrieve = const {
    LanguageCode.en,
    LanguageCode.es,
  },
}) async {
  Word? wordTest = await wordDataService.getWord(word);
  // check that the word exists for the target language
  if (wordTest != null && wordTest.languageCodes.contains(targetLanguage)) {
    debugPrint(
        "Word $word already exists in the word bank for language: $targetLanguage");
    if (!wordTest.needsProcessing) {
      debugPrint("Word $word does not need processing.");
      return true; // word exists already in our word bank
    } else {
      debugPrint("Word $word needs processing.");
    }
  }

  WikiWordData? wordData;
  int? continueIndex = 0;

  // can check search-continue parameter to see if there are more results
  while ((wordData == null || !wordData.languages.contains(targetLanguage)) &&
      continueIndex != null) {
    late final http.Response response;
    try {
      response = await fetchWordData(
        word,
        continueIndex: continueIndex,
        resultsLimit: 7, // limit to 7 results per request
      );
    } catch (e) {
      debugPrint("Error: CheckAndUpdateWord -> $e");
      throw NetworkFailureException(400, "Error: CheckAndUpdateWord -> $e");
    }

    debugPrint("Response status code: ${response.statusCode}");
    debugPrint(
        "Response continue index: ${response.headers['search-continue']}");
    debugPrint("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody =
          jsonDecode(response.body); // get body
      final List<dynamic> searchList = responseBody['search'];

      if (searchList.isEmpty) {
        debugPrint("did not find any search results");
        continueIndex = null; // no more results to check
        continue;
      }

      wordData = fromSearchList(
        word,
        searchList,
        languagesToRetrieve: languagesToRetrieve,
        existingWordData:
            wordData, // TODO: We need to handle the case when a word can be multiple parts of speech
      );
      continueIndex = responseBody['search-continue'];
    } else {
      final int status = response.statusCode;
      debugPrint("did not get a response: $status");
      // throw an exception if the status code is not 200 and process the word as custom somewhere else
      if (wordTest != null) {
        debugPrint(
            "Word $word already exists in the word bank, but could not fetch data from Wikidata API.");
        throw DocumentUpdateFailedException(
            "word exists already in our word bank, but we could not fetch data to update it");
      }

      throw NetworkFailureException(status,
          "Failed to fetch word data for $word. Please check your network connection or try again later.");
    }
  }

  if (wordData != null) {
    debugPrint(
        "Creating New Word from search list: ${wordData.word}, ${wordData.languages}, ${wordData.partsOfSpeech}");
    if (wordTest != null) {
      final bool succcess = await wordDataService.updateWord(
        wordData.word,
        Word.createUpdateMap(
          languageCodes: wordData.languages,
          partOfSpeech: wordData.partsOfSpeech,
          needsProcessing: false, // mark as processed
        ),
      );

      if (!succcess) {
        throw DocumentUpdateFailedException(
          "Failed to update word: $word",
        );
      }
    } else {
      final Word? newWord = await wordDataService.createWord(
        Word(
          word: word,
          languageCodes: wordData.languages,
          partOfSpeech: wordData.partsOfSpeech,
        ),
      );

      if (newWord == null) {
        throw DocumentCreationFailedException(
          "Failed to create word: $word",
        );
      }
    }

    if (wordData.languages.contains(targetLanguage)) {
      debugPrint("Found word $word with language code: $targetLanguage");
      return true; // found the word in the target language
    } else {
      debugPrint(
          "Found word $word, in languages ${wordData.languages}; but not in language code: $targetLanguage");
      return false; // found the word, but not in the target language
    }
  }

  debugPrint(
      "Could not find word $word with any of the languages $languagesToRetrieve");
  return false;
}

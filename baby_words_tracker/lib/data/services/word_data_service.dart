import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:flutter/foundation.dart';

class WordDataService extends ChangeNotifier {
  static final fireRepo = FirestoreRepository();

  //word services
  Future<Word?> createWord(Word word) async {
    String? returnId = await fireRepo.createWithId(
        Word.collectionName, word.word, word.toMap());

    if (returnId == null) {
      debugPrint("Error: create word failed.");
      return null;
    }

    notifyListeners();
    return word;
  }

  Future<Word?> getWord(String id) async {
    final word = await fireRepo.read(Word.collectionName, id);
    if (word == null) return null;

    return Word.fromDataWithId(word);
  }

  Future<List<Word>> getMultipleWords(List<String> ids) async {
    return (await fireRepo.readMultiple(Word.collectionName, ids))
        .map((doc) => Word.fromDataWithId(doc))
        .toList();
  }

  /// Updates a word in the database.
  /// [wordName] is the ID of the word to update.
  /// [updateMap] is a map of fields to update. Use Word.CreateUpdateMap() to create this map.
  /// Returns true if the update was successful, false otherwise.
  /// note: if you do not use Word.CreateUpdateMap() to create the updateMap,
  /// you must ensure that the keys in the map match the fields in the Word model.
  /// Additionally, if an empty key is submitted in your map, the value will be set to null.
  /// Do not use Word.ToMap() to create the updateMap, as it will include all fields,
  /// which may not be what you want. Use Word.CreateUpdateMap() instead.
  Future<bool> updateWord(
    String wordName,
    Map<String, dynamic> updateMap,
  ) async {
    if (updateMap.isEmpty) {
      debugPrint("No updates provided for word: $wordName");
      return true; // No updates to apply
    }

    bool updated =
        await fireRepo.update(Word.collectionName, wordName, updateMap);

    return updated;
  }
}

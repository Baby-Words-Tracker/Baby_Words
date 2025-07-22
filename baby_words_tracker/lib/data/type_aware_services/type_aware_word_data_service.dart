import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/type_aware_services/i_type_aware_data_service.dart';

class TypeAwareWordDataService extends ITypeAwareDataService {
  final WordDataService _wordDataService;

  TypeAwareWordDataService({
    required super.userModelService,
    required WordDataService wordDataService,
  }) : _wordDataService = wordDataService;

  //word services
  Future<Word?> createWord(Word word) {
    return _wordDataService.createWord(word, isDemoType);
  }

  Future<Word?> getWord(String id) {
    return _wordDataService.getWord(id, isDemoType);
  }

  Future<List<Word>> getMultipleWords(List<String> ids) {
    return _wordDataService.getMultipleWords(ids, isDemoType);
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
  ) {
    return _wordDataService.updateWord(
      wordName,
      updateMap,
      isDemoType,
    );
  }
}

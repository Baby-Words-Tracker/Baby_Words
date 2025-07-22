import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/type_aware_services/i_type_aware_data_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';

class TypeAwareChildDataService extends ITypeAwareDataService {
  final ChildDataService _childDataService;

  TypeAwareChildDataService({
    required super.userModelService,
    required ChildDataService childDataService,
  }) : _childDataService = childDataService;

  //child services
  Future<Child?> createChild(
    DateTime cBirthDay,
    String cName,
    List<LanguageCode> language,
    int cWordCount,
    List<String> cParentIDs,
  ) async {
    return _childDataService.createChild(
      cBirthDay,
      cName,
      language,
      cWordCount,
      cParentIDs,
      isDemoType,
    );
  }

  Future<Child?> getChild(String id) {
    return _childDataService.getChild(id, isDemoType);
  }

  Future<List<Child>> getMultipleChildren(List<String> ids) {
    return _childDataService.getMultipleChildren(ids, isDemoType);
  }

  Future<int> getNumWords(String id) {
    return _childDataService.getNumWords(id, isDemoType);
  }

  Future<bool> addVideo(String id, String word, String fileName) {
    return _childDataService.addVideo(id, word, fileName, isDemoType);
  }

  Future<List<LanguageCode>?> getLanguages(String id) {
    return _childDataService.getLanguages(id, isDemoType);
  }

  Future<List<WordTracker>> getAllKnownWords(String id) {
    return _childDataService.getAllKnownWords(id, isDemoType);
  }
}

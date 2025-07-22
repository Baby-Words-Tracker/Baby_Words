import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:flutter/foundation.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/util/language_code.dart';

class ChildDataService {
  final FirestoreRepository _firebaseRepo;

  ChildDataService(this._firebaseRepo);

  String _childCollectionName(bool useDemoCollection) {
    return useDemoCollection
        ? "demo_${Child.collectionName}"
        : Child.collectionName;
  }

  //child services
  Future<Child?> createChild(
    DateTime cBirthDay,
    String cName,
    List<LanguageCode> language,
    int cWordCount,
    List<String> cParentIDs,
    bool useDemoCollection,
  ) async {
    final object = Child(
        birthday: cBirthDay,
        name: cName,
        language: language,
        wordCount: cWordCount,
        parentIDs: cParentIDs);
    String? returnId = await _firebaseRepo.create(
        _childCollectionName(useDemoCollection), object.toMap());

    if (returnId == null) {
      return null;
    }

    return object.copyWith(id: returnId);
  }

  Future<Child?> getChild(String id, bool useDemoCollection) async {
    final child =
        await _firebaseRepo.read(_childCollectionName(useDemoCollection), id);
    if (child == null) return null;
    return Child.fromDataWithId(child);
  }

  Future<List<Child>> getMultipleChildren(
    List<String> ids,
    bool useDemoCollection,
  ) async {
    return (await _firebaseRepo.readMultiple(
            _childCollectionName(useDemoCollection), ids))
        .map((doc) => Child.fromDataWithId(doc))
        .toList();
  }

  Future<int> getNumWords(String id, bool useDemoCollection) async {
    final object =
        await _firebaseRepo.read(_childCollectionName(useDemoCollection), id);
    if (object == null) return 0;

    final child = Child.fromDataWithId(object);
    return child.wordCount;
  }

  Future<bool> addVideo(
    String id,
    String word,
    String fileName,
    bool useDemoCollection,
  ) async {
    debugPrint("Video Filename to be added: $fileName");
    return await _firebaseRepo.updateFieldForSubcollection(
        _childCollectionName(useDemoCollection),
        WordTracker.collectionName,
        id,
        word,
        "videoID",
        fileName);
  }

  Future<List<LanguageCode>?> getLanguages(
    String id,
    bool useDemoCollection,
  ) async {
    final object =
        await _firebaseRepo.read(_childCollectionName(useDemoCollection), id);
    if (object == null) return null;

    final child = Child.fromDataWithId(object);
    return child.language;
  }

  Future<List<WordTracker>> getAllKnownWords(
    String id,
    bool useDemoCollection,
  ) async {
    final List<DataWithId> docs = await _firebaseRepo.readAllFromSubcollection(
        _childCollectionName(useDemoCollection),
        id,
        WordTracker.collectionName);

    List<WordTracker> words = List.empty(growable: true);
    for (DataWithId doc in docs) {
      words.add(WordTracker.fromDataWithId(doc));
    }
    return words;
  }
}

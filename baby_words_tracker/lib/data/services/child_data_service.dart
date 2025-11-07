import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:baby_words_tracker/data/repositories/i_firestore_repository.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:flutter/foundation.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/util/language_code.dart';

class ChildDataService extends ChangeNotifier {
  final IFirestoreRepository firebaseRepo;

  ChildDataService({IFirestoreRepository? repository})
      : firebaseRepo = repository ?? FirestoreRepository();

  //child services
  Future<Child?> createChild(
      DateTime cBirthDay,
      String cName,
      List<LanguageCode> language,
      int cWordCount,
      List<String> cParentIDs) async {
    final object = Child(
        birthday: cBirthDay,
        name: cName,
        language: language,
        wordCount: cWordCount,
        parentIDs: cParentIDs);
    String? returnId =
        await firebaseRepo.create(Child.collectionName, object.toMap());

    if (returnId == null) {
      return null;
    }

    notifyListeners();
    return object.copyWith(id: returnId);
  }

  Future<bool> updateChild(
    String childId, {
    String? name,
    DateTime? birthday,
    List<LanguageCode>? language,
  }) async {
    final Map<String, dynamic> updates = {};
    if (name != null) {
      updates['name'] = name;
    }
    if (birthday != null) {
      updates['birthday'] = birthday;
    }
    if (language != null) {
      updates['languageCodes'] = language.map((code) => code.name).toList();
    }
    if (updates.isEmpty) {
      return true;
    }

    final success =
        await firebaseRepo.update(Child.collectionName, childId, updates);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<Child?> getChild(String id) async {
    final child = await firebaseRepo.read(Child.collectionName, id);
    if (child == null) return null;
    return Child.fromDataWithId(child);
  }

  Future<List<Child>> getMultipleChildren(List<String> ids) async {
    debugPrint("ChildDataService: getMultipleChildren called with ${ids.length} IDs: $ids");
    final docs = await firebaseRepo.readMultiple(Child.collectionName, ids);
    debugPrint("ChildDataService: Retrieved ${docs.length} documents from Firestore");
    final children = docs.map((doc) => Child.fromDataWithId(doc)).toList();
    debugPrint("ChildDataService: Converted to ${children.length} Child objects");
    return children;
  }

  Future<int> getNumWords(String id) async {
    final object = await firebaseRepo.read(Child.collectionName, id);
    if (object == null) return 0;

    final child = Child.fromDataWithId(object);
    return child.wordCount;
  }

  Future<bool> removeParentFromChild(String childId, String parentId) async {
    final data = await firebaseRepo.read(Child.collectionName, childId);
    if (data == null) {
      return false;
    }

    final child = Child.fromDataWithId(data);
    final updatedParentIds =
        child.parentIDs.where((id) => id != parentId).toList();

    final success = await firebaseRepo.update(
      Child.collectionName,
      childId,
      {'parentIDs': updatedParentIds},
    );

    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<List<LanguageCode>?> getLanguages(String id) async {
    final object = await firebaseRepo.read(Child.collectionName, id);
    if (object == null) return null;

    final child = Child.fromDataWithId(object);
    return child.language;
  }

  Future<List<WordTracker>> getAllKnownWords(String id) async {
    final List<DataWithId> docs = await firebaseRepo.readAllFromSubcollection(
        Child.collectionName, id, WordTracker.collectionName);

    List<WordTracker> words = List.empty(growable: true);
    for (DataWithId doc in docs) {
      words.add(WordTracker.fromDataWithId(doc));
    }
    return words;
  }
}

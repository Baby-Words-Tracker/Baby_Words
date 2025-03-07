import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:flutter/foundation.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';

class ChildDataService extends ChangeNotifier {
  static final firebaseRepo = FirestoreRepository();

  //child services
  Future<Child?> createChild(DateTime cBirthDay, String cName, int cWordCount,
      List<String> cParentIDs) async {
    final object = Child(
        birthday: cBirthDay,
        name: cName,
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

  Future<Child?> getChild(String id) async {
    final child = await firebaseRepo.read(Child.collectionName, id);
    if (child == null) return null;
    return Child.fromDataWithId(child);
  }

  Future<List<Child>> getMultipleChildren(List<String> ids) async {
    return (await firebaseRepo.readMultiple(Child.collectionName, ids))
        .map((doc) => Child.fromDataWithId(doc))
        .toList();
  }

  Future<int> getNumWords(String id) async {
    final object = await firebaseRepo.read(Child.collectionName, id);
    if (object == null) return 0;

    final child = Child.fromDataWithId(object);
    return child.wordCount;
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

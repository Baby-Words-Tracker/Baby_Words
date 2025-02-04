import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/repositories/FirestoreRepository.dart';
import 'package:flutter/foundation.dart';

class ChildDataService extends ChangeNotifier {

  static final firebaseRepo = FirestoreRepository();

  //child services
  Future<String> createChild(DateTime cBirthDay, String cName, int cWordCount, List<String> cParentIDs) async {
    final object = Child(birthday: cBirthDay, name: cName, wordCount: cWordCount, parentIDs: cParentIDs);
    late String returnId;
    await firebaseRepo.create("Child", object.toMap()).then(
      (id) {
        returnId = id;
      }
    );

    notifyListeners();
    return returnId; 
  }

  Future<Child> getChild(String id) async {
    return Child.fromDataWithId(await firebaseRepo.read("Child", id));
  }

  Future<int> getNumWords(String id) async {
    final child = Child.fromDataWithId(await firebaseRepo.read("Child", id));
    return child.wordCount; 
  }

}
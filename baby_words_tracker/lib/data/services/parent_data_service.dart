import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:flutter/foundation.dart';

class ParentDataService  extends ChangeNotifier{

  static final fireRepo = FirestoreRepository();

  //Parent services
  Future<Parent?> createParent(Parent parent) async {
    String? returnId = await fireRepo.createWithId(Parent.collectionName, parent.id, parent.toMap());
    
    if (returnId == null) {
      return null;
    }

    if (returnId != parent.id) {
      debugPrint("Error: ParentDataService.createParent returned ID does not match input ID");
      return null;
    }

    notifyListeners();
    return parent;
  }

  Future<Parent?> getParent(String id) async {
    final parent = await fireRepo.read(Parent.collectionName, id);
    if (parent == null) {
      debugPrint("ParentDataService: Failed to get parent by ID");
      return null;
    }
    return Parent.fromDataWithId(parent);
  }

  Future<Parent?> getParentByEmail(String email) async {
    final parentList = await fireRepo.queryByField(Parent.collectionName, "email", email, limit: 1);
    if (parentList.isEmpty) {
      debugPrint("ParentDataService: Failed to get parent by email");
      return null;
    }
    return Parent.fromDataWithId(parentList.first);
  }

  Future<List<Parent>> getMultipleParents(List<String> ids) async {
    return (await fireRepo.readMultiple(Parent.collectionName, ids))
        .map((doc) => Parent.fromDataWithId(doc))
        .toList();
  }

  Future<bool> updateParent(String id, {String? email, String? name, List<String>? childIDs}) async {
    final updateData = Parent.createUpdateMap(email: email, name: name, childIDs: childIDs);
    bool success = await fireRepo.update(Parent.collectionName, id, updateData);

    if (!success) {
      return false;
    }

    notifyListeners();
    return success;
  }

  // TODO: we need this to delete/edit children as well
  // Future<bool> deleteParent(String id) async {
  //   bool success = await fireRepo.delete(Parent.collectionName, id);
  //   if (!success) {
  //     return false;
  //   }
  //   notifyListeners();
  //   return true;
  // }

  Future<void> addChildToParent(String parentId, String childId) async {
    await fireRepo.appendToArrayField(Parent.collectionName, parentId, "childIDs", childId);
    await fireRepo.appendToArrayField(Child.collectionName, childId, "parentIDs", parentId);
    notifyListeners();
  }


  Future<List<Child>> getChildList(String id) async {
    final object = await fireRepo.read(Parent.collectionName, id);
    List<Child> children = List.empty(growable: true);
    if(object == null) return children;

    final parent = Parent.fromDataWithId(object);
    final List<DataWithId> data= await fireRepo.readMultiple(Child.collectionName, parent.childIDs);

    for(DataWithId child in data) {
      children.add(Child.fromDataWithId(child)); 
    }
    return children; 
  }

  
}
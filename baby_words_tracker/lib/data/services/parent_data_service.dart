import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/repositories/FirestoreRepository.dart';
import 'package:flutter/foundation.dart';

class ParentDataService  extends ChangeNotifier{

  static final fireRepo = FirestoreRepository();

  //Parent services
  Future<Parent> createParent(String parEmail, String parName, List<String> parChildIDs) async {
    final par = Parent(email: parEmail, name : parName, childIDs : parChildIDs); 

    String returnId = await fireRepo.create("Parent", par.toMap());
    notifyListeners();

    return par.copyWith(id: returnId);  
  }

  Future<Parent> updateParent(String id, String email, String name, List<String> childIDs) async {
    final parent = Parent(id: id, email: email, name: name, childIDs: childIDs);
    await fireRepo.update("Parent", id, parent.toMap());
    notifyListeners();
    return parent;
  }

  Future<Parent?> getParent(String id) async {
    final parent = await fireRepo.read("Parent", id);
    if (parent == null) {
      return null;
    }
    return Parent.fromDataWithId(parent);
  }

  Future<Parent?> getParentByEmail(String email) async {
    final parentList = await fireRepo.queryByField("Parent", "email", email, limit: 1);
    if (parentList.isEmpty) {
      return null;
    }
    return Parent.fromDataWithId(parentList.first);
  }

  void addChildToParent(String parentId, String childId) async {
    await fireRepo.appendToArrayField("Parent", parentId, "childIDs", childId);
    await fireRepo.appendToArrayField("Child", childId, "parentIDs", parentId);
    notifyListeners();
  }

  Future<List<Child>> getChildList(String id) async {
    final object = await fireRepo.read("Parent", id);
    List<Child> children = List.empty(growable: true);
    if(object == null) return children;

    final parent = Parent.fromDataWithId(object);
    final List<DataWithId> data= await fireRepo.readMultiple("Child", parent.childIDs);

    for(DataWithId child in data) {
      children.add(Child.fromDataWithId(child)); 
    }
    return children; 
  }

  
}
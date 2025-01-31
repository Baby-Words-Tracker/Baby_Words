import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/repositories/FirestoreRepository.dart';

class ParentDataService {

  static final fireRepo = FirestoreRepository();

  //Parent services
  Future<String> createParent(String parEmail, String parName, List<String> parChildIDs ) async {
    final par = Parent(email: parEmail, name : parName, childIDs : parChildIDs); 
    return await fireRepo.create("Parent", par.toMap());  
  }

  Future<Parent> getParent(String id) async {
    return Parent.fromMap(await fireRepo.read("Parent", id));
  }

  void addChildToParent(String parentId, String childId) async {
    await fireRepo.appendToArrayField("Parent", parentId, "childIDs", childId);
    await fireRepo.appendToArrayField("Child", childId, "parentIDs", parentId);
  }

  Future<List<Child>> getChildList(String id) async {
    final parent = Parent.fromMap(await fireRepo.read("Parent", id));
    List<Child> children = List.empty(growable: true);
    final childService = ChildDataService();
    for(String childId in parent.childIDs) {
      children.add(await childService.getChild(childId)); 
    }
    return children; 
  }

  
}
import 'package:baby_words_tracker/data/models/parent.dart';
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

  
}
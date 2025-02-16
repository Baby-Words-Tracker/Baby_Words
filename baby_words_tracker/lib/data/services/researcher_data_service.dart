import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/data/repositories/FirestoreRepository.dart';
import 'package:flutter/foundation.dart';

class ResearcherDataService extends ChangeNotifier{

  static final fireRepo = FirestoreRepository();

  //Reseacher services
   Future<Researcher?> createResearcher(String email, String name, String institution, [String? phoneNumber]) async {
    final object = Researcher(email: email, name: name, institution: institution, phoneNumber: phoneNumber);
    String? returnId = await fireRepo.create("Researcher", object.toMap());

    if (returnId == null) {
      return null;
    }

    notifyListeners();
    return object.copyWith(id: returnId);
  }

  Future<Researcher?> updateResearcher(String id, String email, String name, String institution, [String? phoneNumber]) async {
    final object = Researcher(id: id, email: email, name: name, institution: institution, phoneNumber: phoneNumber);
    bool success = await fireRepo.update("Researcher", id, object.toMap());

    if (!success) {
      return null;
    }

    notifyListeners();
    return object;
  }

  Future<Researcher?> updateResearcherFromModel(Researcher researcher) async {
    if (researcher.id == null) {
      debugPrint("Error: updateResearcherFromModel called with researcher object that has null ID");
      return null;
    }

    bool success = await fireRepo.update("Researcher", researcher.id!, researcher.toMap());

    if (!success) {
      return null;
    }

    notifyListeners();
    return researcher;
  }

  Future<Researcher?> getResearcher(String id) async {
    final researcher = await fireRepo.read("Researcher", id);
    if (researcher == null) return null;
    return Researcher.fromDataWithId(researcher);
  }

  Future<Researcher?> getResearcherByEmail(String email) async {
    final researcherList = await fireRepo.queryByField("Researcher", "email", email, limit: 1);
    if (researcherList.isEmpty) {
      return null;
    }
    return Researcher.fromDataWithId(researcherList.first);
  }

}
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/data/repositories/FirestoreRepository.dart';
import 'package:flutter/foundation.dart';

class ResearcherDataService extends ChangeNotifier{

  static final fireRepo = FirestoreRepository();

  //Reseacher services
   Future<Researcher> createResearcher(String email, String name, String institution, [String? phoneNumber]) async {
    final object = Researcher(email: email, name: name, institution: institution, phoneNumber: phoneNumber);
    String returnId = await fireRepo.create("Researcher", object.toMap())

    notifyListeners();
    return object.copyWith(id: returnId);
  }

  Future<Researcher> getResearcher(String id) async {
    return Researcher.fromDataWithId(await fireRepo.read("Researcher", id));
  }

}
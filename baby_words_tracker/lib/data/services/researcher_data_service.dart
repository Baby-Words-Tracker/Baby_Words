import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/data/repositories/FirestoreRepository.dart';

class ResearcherDataService {

  static final fireRepo = FirestoreRepository();

  //Reseacher services
   Future<String> createResearcher(String email, String name, String institution, [String? phoneNumber]) async {
    final object = Researcher(email: email, name: name, institution: institution, phoneNumber: phoneNumber);
    return await fireRepo.create("Researcher", object.toMap());
  }

  Future<Researcher> getResearcher(String id) async {
    return Researcher.fromDataWithId(await fireRepo.read("Researcher", id));
  }

}
import 'package:baby_words_tracker/data/listeners/i_document_listener.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:flutter/foundation.dart';

class ResearcherDataService extends ChangeNotifier {
  static final _firestoreRepository = FirestoreRepository();

  //Reseacher services
  Future<Researcher?> createResearcher(Researcher researcher) async {
    String? returnId = await _firestoreRepository.createWithId(
        Researcher.collectionName, researcher.id, researcher.toMap(), true);

    if (returnId == null) {
      return null;
    }

    if (returnId != researcher.id) {
      debugPrint(
          "Error: ResearcherDataService: createResearcher returned ID does not match input ID");
      return null;
    }

    notifyListeners();
    return researcher;
  }

  Future<Researcher?> getResearcher(String id) async {
    final researcher =
        await _firestoreRepository.read(Researcher.collectionName, id);
    if (researcher == null) {
      debugPrint("ResearcherDataService: Failed to get researcher by ID");
      return null;
    }
    return Researcher.fromDataWithId(researcher);
  }

  Future<Researcher?> getResearcherByEmail(String email) async {
    final researcherList = await _firestoreRepository
        .queryByField(Researcher.collectionName, "email", email, limit: 1);
    if (researcherList.isEmpty) {
      return null;
    }
    return Researcher.fromDataWithId(researcherList.first);
  }

  Future<List<Researcher>> getMultipleResearchers(List<String> ids) async {
    return (await _firestoreRepository.readMultiple(
            Researcher.collectionName, ids))
        .map((doc) => Researcher.fromDataWithId(doc))
        .toList();
  }

  Future<bool> updateResearcher(String id,
      {String? email,
      String? name,
      String? institution,
      String? phoneNumber}) async {
    final updateData = Researcher.createUpdateMap(
        email: email,
        name: name,
        institution: institution,
        phoneNumber: phoneNumber);
    bool success = await _firestoreRepository.update(
        Researcher.collectionName, id, updateData);

    if (!success) {
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<bool> deleteResearcher(String id) async {
    bool success =
        await _firestoreRepository.delete(Researcher.collectionName, id);

    if (!success) {
      return false;
    }

    notifyListeners();
    return true;
  }

  IDocumentListener<Researcher> getUserListener(String id) {
    return _firestoreRepository.getDocumentListener<Researcher>(
      path: '${Researcher.collectionName}/$id',
      convertDataWithId: (data) => Researcher.fromDataWithId(data),
    );
  }
}

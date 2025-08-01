import 'package:baby_words_tracker/data/listeners/i_document_listener.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:flutter/foundation.dart';

class ResearcherDataService {
  final FirestoreRepository _firestoreRepository;

  ResearcherDataService(this._firestoreRepository);

  //Reseacher services
  Future<Researcher?> createResearcher(
    Researcher researcher,
    bool isDemoType,
  ) async {
    String? returnId = await _firestoreRepository.createWithId(
        Researcher.collectionName.demoAwareCollectionName(isDemoType),
        researcher.id,
        researcher.toMap(),
        true);

    if (returnId == null) {
      return null;
    }

    if (returnId != researcher.id) {
      debugPrint(
          "Error: ResearcherDataService: createResearcher returned ID does not match input ID");
      return null;
    }

    return researcher;
  }

  Future<Researcher?> getResearcher(String id, bool isDemoType) async {
    final researcher = await _firestoreRepository.read(
        Researcher.collectionName.demoAwareCollectionName(isDemoType), id);
    if (researcher == null) {
      debugPrint("ResearcherDataService: Failed to get researcher by ID");
      return null;
    }
    return Researcher.fromDataWithId(researcher);
  }

  Future<Researcher?> getResearcherByEmail(
      String email, bool isDemoType) async {
    final researcherList = await _firestoreRepository.queryByField(
        Researcher.collectionName.demoAwareCollectionName(isDemoType),
        "email",
        email,
        limit: 1);
    if (researcherList.isEmpty) {
      return null;
    }
    return Researcher.fromDataWithId(researcherList.first);
  }

  Future<List<Researcher>> getMultipleResearchers(
      List<String> ids, bool isDemoType) async {
    return (await _firestoreRepository.readMultiple(
            Researcher.collectionName.demoAwareCollectionName(isDemoType), ids))
        .map((doc) => Researcher.fromDataWithId(doc))
        .toList();
  }

  Future<bool> updateResearcher(
    String id,
    bool isDemoType, {
    String? email,
    String? name,
    String? institution,
    String? phoneNumber,
    bool? acceptedPrivacyPolicy,
    String? policyVersion,
    DateTime? consentDate,
  }) async {
    final updateData = Researcher.createUpdateMap(
      email: email,
      name: name,
      institution: institution,
      phoneNumber: phoneNumber,
      acceptedPrivacyPolicy: acceptedPrivacyPolicy,
      policyVersion: policyVersion,
      consentDate: consentDate,
    );
    bool success = await _firestoreRepository.update(
      Researcher.collectionName.demoAwareCollectionName(isDemoType),
      id,
      updateData,
    );

    if (!success) {
      return false;
    }

    return true;
  }

  Future<bool> deleteResearcher(String id, bool isDemoType) async {
    bool success = await _firestoreRepository.delete(
      Researcher.collectionName.demoAwareCollectionName(isDemoType),
      id,
    );

    if (!success) {
      return false;
    }

    return true;
  }

  IDocumentListener<Researcher> getUserListener(String id, bool isDemoType) {
    return _firestoreRepository.getDocumentListener<Researcher>(
      path:
          '${Researcher.collectionName.demoAwareCollectionName(isDemoType)}/$id',
      convertDataWithId: (data) => Researcher.fromDataWithId(data),
    );
  }
}

import 'package:baby_words_tracker/data/listeners/i_document_listener.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:baby_words_tracker/util/language_code.dart';

class ParentDataService {
  final FirestoreRepository _firestoreRepository;

  ParentDataService(this._firestoreRepository);

  //Parent services
  Future<Parent?> createParent(Parent parent, bool useDemoCollection) async {
    String? returnId = await _firestoreRepository.createWithId(
        Parent.collectionName.demoAwareCollectionName(useDemoCollection),
        parent.id,
        parent.toMap(),
        true);

    if (returnId == null) {
      return null;
    }

    if (returnId != parent.id) {
      debugPrint(
          "Error: ParentDataService.createParent returned ID does not match input ID");
      return null;
    }

    return parent;
  }

  Future<Parent?> getParent(String id, bool useDemoCollection) async {
    final parent = await _firestoreRepository.read(
        Parent.collectionName.demoAwareCollectionName(useDemoCollection), id);
    if (parent == null) {
      debugPrint("ParentDataService: Failed to get parent by ID");
      return null;
    }
    return Parent.fromDataWithId(parent);
  }

  Future<Parent?> getParentByEmail(String email, bool useDemoCollection) async {
    final parentList = await _firestoreRepository.queryByField(
        Parent.collectionName.demoAwareCollectionName(useDemoCollection),
        "email",
        email,
        limit: 1);
    if (parentList.isEmpty) {
      debugPrint("ParentDataService: Failed to get parent by email");
      return null;
    }
    return Parent.fromDataWithId(parentList.first);
  }

  Future<List<Parent>> getMultipleParents(
      List<String> ids, bool useDemoCollection) async {
    return (await _firestoreRepository.readMultiple(
            Parent.collectionName.demoAwareCollectionName(useDemoCollection),
            ids))
        .map((doc) => Parent.fromDataWithId(doc))
        .toList();
  }

  Future<bool> updateParent(
    String id,
    bool useDemoCollection, {
    List<String>? childIDs,
    LanguageCode? language,
    bool? consentFormComplete,
    bool? demographicSurveyComplete,
    bool? preStudySurveyComplete,
    bool? acceptedPrivacyPolicy,
    String? policyVersion,
    DateTime? consentDate,
  }) async {
    final updateData = Parent.createUpdateMap(
      childIDs: childIDs,
      language: language,
      consentFormComplete: consentFormComplete,
      demographicSurveyComplete: demographicSurveyComplete,
      preStudySurveyComplete: preStudySurveyComplete,
      acceptedPrivacyPolicy: acceptedPrivacyPolicy,
      policyVersion: policyVersion,
      consentDate: consentDate,
    );
    bool success = await _firestoreRepository.update(
        Parent.collectionName.demoAwareCollectionName(useDemoCollection),
        id,
        updateData);

    if (!success) {
      return false;
    }

    return success;
  }

  // TODO: this function may also have to delete children or
  //  store them in a data structure so we don't accrue hanging data.
  // Future<bool> deleteParent(String id, bool useDemoCollection) async {
  //   bool success = await fireRepo.delete(Parent.collectionName.demoAwareCollectionName(useDemoCollection), id);
  //   if (!success) {
  //     return false;
  //   }
  //   return true;
  // }

  Future<void> addChildToParent(
      String parentId, String childId, bool useDemoCollection) async {
    await _firestoreRepository.appendToArrayField(
        Parent.collectionName.demoAwareCollectionName(useDemoCollection),
        parentId,
        "childIDs",
        childId);
    await _firestoreRepository.appendToArrayField(
        Child.collectionName.demoAwareCollectionName(useDemoCollection),
        childId,
        "parentIDs",
        parentId);
  }

  Future<List<Child>> getChildList(String id, bool useDemoCollection) async {
    final object = await _firestoreRepository.read(
        Parent.collectionName.demoAwareCollectionName(useDemoCollection), id);
    List<Child> children = List.empty(growable: true);
    if (object == null) return children;

    final parent = Parent.fromDataWithId(object);
    final List<DataWithId> data = await _firestoreRepository.readMultiple(
        Child.collectionName.demoAwareCollectionName(useDemoCollection),
        parent.childIDs);

    for (DataWithId child in data) {
      children.add(Child.fromDataWithId(child));
    }
    return children;
  }

  Future<LanguageCode?> getLanguage(String id, bool useDemoCollection) async {
    final object = await _firestoreRepository.read(
        Parent.collectionName.demoAwareCollectionName(useDemoCollection), id);

    if (object == null) {
      debugPrint("unable to get parent language");
      return null;
    }

    return Parent.fromDataWithId(object).language;
  }

  IDocumentListener<Parent> getUserListener(String id, bool useDemoCollection) {
    return _firestoreRepository.getDocumentListener<Parent>(
      path:
          '${Parent.collectionName.demoAwareCollectionName(useDemoCollection)}/$id',
      convertDataWithId: (data) => Parent.fromDataWithId(data),
    );
  }
}

import 'package:baby_words_tracker/data/listeners/i_document_listener.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/type_aware_services/i_type_aware_data_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';

class TypeAwareParentDataService extends ITypeAwareDataService {
  final ParentDataService _parentDataService;

  TypeAwareParentDataService({
    required super.userModelService,
    required ParentDataService parentDataService,
  }) : _parentDataService = parentDataService;

  Future<Parent?> createParent(Parent parent) {
    return _parentDataService.createParent(parent, isDemoType);
  }

  Future<Parent?> getParent(String id) {
    return _parentDataService.getParent(id, isDemoType);
  }

  Future<Parent?> getParentByEmail(String email) {
    return _parentDataService.getParentByEmail(email, isDemoType);
  }

  Future<List<Parent>> getMultipleParents(List<String> ids) {
    return _parentDataService.getMultipleParents(ids, isDemoType);
  }

  Future<bool> updateParent(
    String id, {
    List<String>? childIDs,
    LanguageCode? language,
    bool? consentFormComplete,
    bool? demographicSurveyComplete,
    bool? preStudySurveyComplete,
    bool? acceptedPrivacyPolicy,
    String? policyVersion,
    DateTime? consentDate,
  }) {
    return _parentDataService.updateParent(
      id,
      isDemoType,
      childIDs: childIDs,
      language: language,
      consentFormComplete: consentFormComplete,
      demographicSurveyComplete: demographicSurveyComplete,
      preStudySurveyComplete: preStudySurveyComplete,
      acceptedPrivacyPolicy: acceptedPrivacyPolicy,
      policyVersion: policyVersion,
      consentDate: consentDate,
    );
  }

  Future<void> addChildToParent(
    String parentId,
    String childId,
  ) {
    return _parentDataService.addChildToParent(parentId, childId, isDemoType);
  }

  Future<List<Child>> getChildList(String id) {
    return _parentDataService.getChildList(id, isDemoType);
  }


  Future<LanguageCode?> getLanguage(String id) {
    return _parentDataService.getLanguage(id, isDemoType);
  }

  IDocumentListener<Parent> getUserListener(String id) {
    return _parentDataService.getUserListener(id, isDemoType);
  }
}

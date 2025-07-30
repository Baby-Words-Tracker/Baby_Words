import 'package:baby_words_tracker/data/listeners/i_document_listener.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/type_aware_services/i_type_aware_data_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';

class TypeAwareParentDataService extends ITypeAwareDataService {
  final ParentDataService _parentDataService;

  TypeAwareParentDataService({
    required super.authenticationService,
    required ParentDataService parentDataService,
  }) : _parentDataService = parentDataService;

  Future<Parent?> createParent(Parent parent) {
    return _parentDataService.createParent(parent, isDemoUser);
  }

  Future<Parent?> getParent(String id) {
    return _parentDataService.getParent(id, isDemoUser);
  }

  Future<Parent?> getParentByEmail(String email) {
    return _parentDataService.getParentByEmail(email, isDemoUser);
  }

  Future<List<Parent>> getMultipleParents(List<String> ids) {
    return _parentDataService.getMultipleParents(ids, isDemoUser);
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
      isDemoUser,
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
    return _parentDataService.addChildToParent(parentId, childId, isDemoUser);
  }

  Future<List<Child>> getChildList(String id) {
    return _parentDataService.getChildList(id, isDemoUser);
  }

  Future<LanguageCode?> getLanguage(String id) {
    return _parentDataService.getLanguage(id, isDemoUser);
  }

  IDocumentListener<Parent> getUserListener(String id) {
    return _parentDataService.getUserListener(id, isDemoUser);
  }
}

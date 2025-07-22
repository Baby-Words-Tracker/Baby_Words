import 'package:baby_words_tracker/data/listeners/i_document_listener.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/data/services/researcher_data_service.dart';
import 'package:baby_words_tracker/data/type_aware_services/i_type_aware_data_service.dart';

class TypeAwareResearcherDataService extends ITypeAwareDataService {
  final ResearcherDataService _researcherDataService;

  TypeAwareResearcherDataService({
    required super.userModelService,
    required ResearcherDataService researcherDataService,
  }) : _researcherDataService = researcherDataService;

  //Reseacher services
  Future<Researcher?> createResearcher(Researcher researcher) {
    return _researcherDataService.createResearcher(
      researcher,
      isDemoType,
    );
  }

  Future<Researcher?> getResearcher(String id) {
    return _researcherDataService.getResearcher(
      id,
      isDemoType,
    );
  }

  Future<Researcher?> getResearcherByEmail(String email) {
    return _researcherDataService.getResearcherByEmail(
      email,
      isDemoType,
    );
  }

  Future<List<Researcher>> getMultipleResearchers(List<String> ids) {
    return _researcherDataService.getMultipleResearchers(
      ids,
      isDemoType,
    );
  }

  Future<bool> updateResearcher(
    String id, {
    String? email,
    String? name,
    String? institution,
    String? phoneNumber,
    bool? acceptedPrivacyPolicy,
    String? policyVersion,
    DateTime? consentDate,
  }) {
    return _researcherDataService.updateResearcher(
      id,
      isDemoType,
      email: email,
      name: name,
      institution: institution,
      phoneNumber: phoneNumber,
      acceptedPrivacyPolicy: acceptedPrivacyPolicy,
      policyVersion: policyVersion,
      consentDate: consentDate,
    );
  }

  Future<bool> deleteResearcher(String id) {
    return _researcherDataService.deleteResearcher(
      id,
      isDemoType,
    );
  }

  IDocumentListener<Researcher> getUserListener(String id) {
    return _researcherDataService.getUserListener(
      id,
      isDemoType,
    );
  }
}

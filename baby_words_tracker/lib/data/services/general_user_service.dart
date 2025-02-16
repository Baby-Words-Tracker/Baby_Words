import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/researcher_data_service.dart';

import 'package:baby_words_tracker/util/user_type.dart';
import 'package:baby_words_tracker/util/pair.dart';


class GeneralUserService {

  ParentDataService _parentDataService;
  ResearcherDataService _researcherDataService;

  GeneralUserService({
    required ParentDataService parentDataService, 
    required ResearcherDataService researcherDataService
  }) : _parentDataService = parentDataService, 
       _researcherDataService = researcherDataService;

  Future<Pair<dynamic, UserType>> getUser(String email, UserType? expectedType) async {
    if (expectedType == UserType.parent) {
      final parent = await _parentDataService.getParentByEmail(email);
      if (parent != null) {
        return Pair(parent, UserType.parent);
      }
    } else if (expectedType == UserType.researcher) {
      final researcher = await _researcherDataService.getResearcherByEmail(email);
      if (researcher != null) {
        return Pair(researcher, UserType.researcher);
      }
    }

    if (expectedType != UserType.parent) {
      final parent = await _parentDataService.getParent(email);
      if (parent != null) {
        return Pair(parent, UserType.parent);
      }
    }

    if (expectedType != UserType.researcher) {
      final researcher = await _researcherDataService.getResearcher(email);
      if (researcher != null) {
        return Pair(researcher, UserType.researcher);
      }
    }

    return Pair(null, UserType.unauthenticated);
  }

  
}
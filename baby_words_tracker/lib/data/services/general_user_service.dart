import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/researcher_data_service.dart';

import 'package:baby_words_tracker/util/user_type.dart';
import 'package:baby_words_tracker/util/pair.dart';
import 'package:flutter/foundation.dart';


class GeneralUserService {

  final ParentDataService _parentDataService;
  final ResearcherDataService _researcherDataService;

  GeneralUserService({
    required ParentDataService parentDataService, 
    required ResearcherDataService researcherDataService
  }) : _parentDataService = parentDataService, 
       _researcherDataService = researcherDataService;

  Future<Pair<dynamic, UserType>> createUser(String email, String name, UserType userType) async {
    if (userType == UserType.parent) {
      final parent = await _parentDataService.createParent(email, name, []);
      if (parent != null) {
        return Pair(parent, UserType.parent);
      }
    } else if (userType == UserType.researcher) {
      final researcher = await _researcherDataService.createResearcher(email, name, "");
      if (researcher != null) {
        return Pair(researcher, UserType.researcher);
      }
    }

    return Pair(null, UserType.unauthenticated);
  }

  Future<Pair<dynamic, UserType>> _queryUserByType(UserType type, String email) async {
    switch (type) {
      case UserType.parent:
        final parent = await _parentDataService.getParentByEmail(email);
        if (parent != null) {
          return Pair(parent, UserType.parent);
        }
        break;
      case UserType.researcher:
        final researcher = await _researcherDataService.getResearcherByEmail(email);
        if (researcher != null) {
          return Pair(researcher, UserType.researcher);
        }
        break;
      default:
        return Pair(null, UserType.unauthenticated);
    }
    return Pair(null, UserType.unauthenticated);
  }

  // TODO: remove logging here, I am just being safe since this is still kind of new
  Future<Pair<dynamic, UserType>> getUser(String email, {UserType? expectedType}) async {
    debugPrint("GeneralUserService: getUser() email: $email, expectedType: $expectedType");

    // if there is no expected type, run simultaneous queries
    if (expectedType == null || expectedType == UserType.unauthenticated) {
      debugPrint("GeneralUserService: getUser() running simultaneous queries");
      final results = await Future.wait([
        _parentDataService.getParentByEmail(email),
        _researcherDataService.getResearcherByEmail(email)
      ]);

      debugPrint("GeneralUserService: getUser() simultaneous queries results: $results");

      if (results[0] != null) {
        return Pair(results[0], UserType.parent);
      } else if (results[1] != null) {
        return Pair(results[1], UserType.researcher);
      }
    } 
    else { // else run the query for the expected type then any other types

      debugPrint("GeneralUserService: getUser() running query for expected type: $expectedType");
      final expectedResult = await _queryUserByType(expectedType, email);
      if (expectedResult.first != null) {
        return expectedResult;
      }

      debugPrint("GeneralUserService: getUser() expected type not found, running query for other types");
      if (expectedType != UserType.parent) {
        final parent = await _parentDataService.getParentByEmail(email);
        debugPrint("GeneralUserService: getUser() parent: $parent");
        if (parent != null) {
          return Pair(parent, UserType.parent);
        }
      }

      if (expectedType != UserType.researcher) {
        final researcher = await _researcherDataService.getResearcherByEmail(email);
        debugPrint("GeneralUserService: getUser() researcher: $researcher");
        if (researcher != null) {
          return Pair(researcher, UserType.researcher);
        }
      }
    }

    debugPrint("GeneralUserService: getUser() no user found");
    return Pair(null, UserType.unauthenticated); // if no user found return unauthenticated
  }

  
}
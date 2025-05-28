import 'package:baby_words_tracker/data/exceptions/document_not_found_exception.dart';
import 'package:baby_words_tracker/data/listeners/i_document_listener.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/researcher_data_service.dart';
import 'package:baby_words_tracker/exceptions/action_failed_exception.dart';

import 'package:baby_words_tracker/util/user_type.dart';
import 'package:baby_words_tracker/util/pair.dart';
import 'package:baby_words_tracker/util/user_type_collection_mapper.dart';
import 'package:flutter/foundation.dart';

class GeneralUserService {
  final ParentDataService _parentDataService;
  final ResearcherDataService _researcherDataService;
  final FirestoreRepository _firestoreRepository = FirestoreRepository();

  GeneralUserService(
      {required ParentDataService parentDataService,
      required ResearcherDataService researcherDataService})
      : _parentDataService = parentDataService,
        _researcherDataService = researcherDataService;

  Future<Pair<dynamic, UserType>> createUser(
      {required UserType userType,
      required String id,
      String? email,
      String? name}) async {
    if (userType == UserType.parent) {
      final parent = await _parentDataService.createParent(Parent(id: id));
      if (parent != null) {
        return Pair(parent, UserType.parent);
      }
    } else if (userType == UserType.researcher) {
      final researcher = await _researcherDataService
          .createResearcher(Researcher(id: id, email: email, name: name));
      if (researcher != null) {
        return Pair(researcher, UserType.researcher);
      }
    }

    return Pair(null, UserType.unauthenticated);
  }

  Future<Pair<dynamic, UserType>> _queryUserByType(
      UserType type, String userId) async {
    switch (type) {
      case UserType.parent:
        final parent = await _parentDataService.getParent(userId);
        if (parent != null) {
          return Pair(parent, UserType.parent);
        }
        break;
      case UserType.researcher:
        final researcher = await _researcherDataService.getResearcher(userId);
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
  Future<Pair<dynamic, UserType>> getUser(String userId,
      {UserType? expectedType}) async {
    debugPrint(
        "GeneralUserService: getUser() id: $userId, expectedType: $expectedType");

    // if there is no expected type, run simultaneous queries
    if (expectedType == null || expectedType == UserType.unauthenticated) {
      debugPrint("GeneralUserService: getUser() running simultaneous queries");
      // run both queries simultaneously
      final results = await Future.wait([
        _parentDataService.getParent(userId),
        _researcherDataService.getResearcher(userId)
      ]);

      debugPrint(
          "GeneralUserService: getUser() simultaneous queries results: $results");
      if (results[1] != null) {
        return Pair(results[1], UserType.researcher);
      } else if (results[0] != null) {
        return Pair(results[0], UserType.parent);
      }
    } else {
      // else run the query for the expected type then any other types

      debugPrint(
          "GeneralUserService: getUser() running query for expected type: $expectedType");
      final expectedResult = await _queryUserByType(expectedType, userId);
      if (expectedResult.first != null) {
        debugPrint("GeneralUserService: getUser() expected type found");
        return expectedResult;
      }

      debugPrint(
          "GeneralUserService: getUser() expected type not found, running query for other types");
      if (expectedType != UserType.parent) {
        final parent = await _parentDataService.getParent(userId);
        debugPrint("GeneralUserService: getUser() parent: $parent");
        if (parent != null) {
          return Pair(parent, UserType.parent);
        }
      }

      if (expectedType != UserType.researcher) {
        final researcher = await _researcherDataService.getResearcher(userId);
        debugPrint("GeneralUserService: getUser() researcher: $researcher");
        if (researcher != null) {
          return Pair(researcher, UserType.researcher);
        }
      }
    }

    debugPrint("GeneralUserService: getUser() no user found");
    return Pair(null,
        UserType.unauthenticated); // if no user found return unauthenticated
  }

  Future<Pair<IDocumentListener?, UserType>> getUserListener(String userId,
      {UserType? expectedListenerType}) async {
    if (expectedListenerType == UserType.unauthenticated ||
        expectedListenerType == null) {
      debugPrint("GeneralUserService: getUserListener() expectedType is null");
      Pair<dynamic, UserType> result =
          await getUser(userId, expectedType: expectedListenerType);
      expectedListenerType = result.second;
      debugPrint(
          "GeneralUserService: getUserListener() expectedListenerType: $expectedListenerType");
    }

    switch (expectedListenerType) {
      case UserType.researcher:
        return Pair(
          _researcherDataService.getUserListener(userId),
          UserType.researcher,
        );
      case UserType.parent:
        return Pair(
          _parentDataService.getUserListener(userId),
          UserType.parent,
        );
      default:
        return Pair(null, UserType.unauthenticated);
    }
  }

  Future<Pair<dynamic, UserType>?> changeUserType(
      String userId, UserType newType,
      {UserType? expectedType}) async {
    debugPrint(
        "GeneralUserService: changeUserType() userId: $userId, newType: $newType");

    // set collection names based on user types
    List<String> fromCollections = UserTypeCollectionMapper.allCollectionNames;
    String? expectedCollection = expectedType?.collectionName;
    String? toCollection = newType.collectionName;

    if (toCollection == null) {
      throw ArgumentError(
          "GeneralUserService: changeUserType() new type is invalid: $newType");
    }

    // Move the document to the new collection using a transaction
    late final Pair<DataWithId, String>? newUser;
    try {
      newUser = await _firestoreRepository.changeUserType(
          userId, fromCollections, toCollection,
          expectedCollectionName: expectedCollection);
    } on DocumentNotFoundException catch (e) {
      debugPrint("GeneralUserService: User not found: $e");
      return null;
    } catch (e) {
      debugPrint("GeneralUserService: changeUserType() error: $e");
      rethrow;
    }

    if (newUser == null) {
      debugPrint("GeneralUserService: changeUserType() failed to move user");
      throw ActionFailedException(
          "GeneralUserService: changeUserType() failed to move user $userId to $toCollection");
    } else {
      debugPrint(
          "GeneralUserService: changeUserType() user moved successfully");
      // return the new user
      switch (newType) {
        case UserType.parent:
          return Pair(Parent.fromDataWithId(newUser.first), newType);
        case UserType.researcher:
          return Pair(Researcher.fromDataWithId(newUser.first), newType);
        default:
          throw ActionFailedException(
              "GeneralUserService: changeUserType() new type is invalid after the move. This should never happen.");
      }
    }
  }
}

import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/data/listeners/i_document_listener.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:baby_words_tracker/data/type_aware_services/type_aware_parent_data_service.dart';
import 'package:baby_words_tracker/data/type_aware_services/type_aware_researcher_data_service.dart';
import 'package:baby_words_tracker/exceptions/action_failed_exception.dart';
import 'package:baby_words_tracker/exceptions/document_not_found_exception.dart';
import 'package:baby_words_tracker/util/collection_name.dart';
import 'package:baby_words_tracker/util/pair.dart';
import 'package:baby_words_tracker/util/policies_and_consent/privacy_policy_information.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type_collection_mapper.dart';
import 'package:flutter/foundation.dart';

class GeneralUserService {
  final FirestoreRepository _firestoreRepository = FirestoreRepository();

  final TypeAwareParentDataService _parentDataService;
  final TypeAwareResearcherDataService _researcherDataService;
  final AuthenticationService _authenticationService;

  GeneralUserService(
      {required TypeAwareParentDataService parentDataService,
      required TypeAwareResearcherDataService researcherDataService,
      required AuthenticationService authenticationService})
      : _parentDataService = parentDataService,
        _researcherDataService = researcherDataService,
        _authenticationService = authenticationService;

  Future<Pair<dynamic, UserType>> createUser(
      {required UserType userType,
      required String id,
      String? email,
      String? name}) async {
    if (userType == UserType.parent_type) {
      final parent = await _parentDataService.createParent(Parent(id: id));
      if (parent != null) {
        return Pair(parent, UserType.parent_type);
      }
    } else if (userType == UserType.researcher_type) {
      final researcher = await _researcherDataService
          .createResearcher(Researcher(id: id, email: email, name: name));
      if (researcher != null) {
        return Pair(researcher, UserType.researcher_type);
      }
    }

    return Pair(null, UserType.unauthenticated_type);
  }

  Future<Pair<dynamic, UserType>> _queryUserByType(
      UserType type, String userId) async {
    switch (type) {
      case UserType.parent_type:
        final parent = await _parentDataService.getParent(userId);
        if (parent != null) {
          return Pair(parent, type);
        }
        break;
      case UserType.researcher_type:
        final researcher = await _researcherDataService.getResearcher(userId);
        if (researcher != null) {
          return Pair(researcher, type);
        }
        break;
      default:
        return Pair(null, UserType.unauthenticated_type);
    }
    return Pair(null, UserType.unauthenticated_type);
  }

  // TODO: remove logging here, I am just being safe since this is still kind of new
  Future<Pair<dynamic, UserType>> getUser(String userId,
      {UserType? expectedType}) async {
    debugPrint(
        "GeneralUserService: getUser() id: $userId, expectedType: $expectedType");

    // if there is no expected type, run simultaneous queries
    if (expectedType == null || expectedType == UserType.unauthenticated_type) {
      debugPrint("GeneralUserService: getUser() running simultaneous queries");
      // run both queries simultaneously
      final results = await Future.wait([
        _parentDataService.getParent(userId),
        _researcherDataService.getResearcher(userId)
      ]);

      debugPrint(
          "GeneralUserService: getUser() simultaneous queries results: $results");
      if (results[1] != null) {
        return Pair(results[1], UserType.researcher_type);
      } else if (results[0] != null) {
        return Pair(results[0], UserType.parent_type);
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
      if (expectedType != UserType.parent_type) {
        final parent = await _parentDataService.getParent(userId);
        debugPrint("GeneralUserService: getUser() parent: $parent");
        if (parent != null) {
          return Pair(parent, UserType.parent_type);
        }
      }

      if (expectedType != UserType.researcher_type) {
        final researcher = await _researcherDataService.getResearcher(userId);
        debugPrint("GeneralUserService: getUser() researcher: $researcher");
        if (researcher != null) {
          return Pair(researcher, UserType.researcher_type);
        }
      }
    }

    debugPrint("GeneralUserService: getUser() no user found");
    return Pair(
        null,
        UserType
            .unauthenticated_type); // if no user found return unauthenticated
  }

  /// Returns a user listener for the given userId and expected type.
  /// If the expected type is null, it will return a listener for the user type
  /// that is currently stored in the database.
  /// If the user is not found, it will return a null listener and the unauthenticated type.
  /// If the user is found, it will return a listener for the user type
  /// and the user type.
  Future<Pair<IDocumentListener?, UserType>> getUserListener(String userId,
      {UserType? expectedListenerType}) async {
    Pair<dynamic, UserType> searchResult =
        await getUser(userId, expectedType: expectedListenerType);
    final UserType actualUserType = searchResult.second;
    debugPrint(
        "GeneralUserService: getUserListener() expectedListenerType: $expectedListenerType");

    switch (actualUserType) {
      case UserType.researcher_type:
        return Pair(
          _researcherDataService.getUserListener(userId),
          actualUserType,
        );
      case UserType.parent_type:
        return Pair(
          _parentDataService.getUserListener(userId),
          actualUserType,
        );
      default:
        return Pair(null, UserType.unauthenticated_type);
    }
  }

  Future<Pair<dynamic, UserType>?> changeUserStorageType(
      String userId, UserType newType,
      {UserType? expectedType}) async {
    debugPrint(
        "GeneralUserService: changeUserStorageLocationType() userId: $userId, newType: $newType");

    // set collection names based on user types
    List<CollectionName> fromCollections =
        UserTypeCollectionMapper.allCollectionNames;
    CollectionName? expectedCollection =
        expectedType?.collectionName; // TODO: make demo aware
    CollectionName? toCollection = newType.collectionName;

    if (toCollection == null) {
      throw ArgumentError(
          "GeneralUserService: changeUserType() new type is invalid: $newType");
    }

    // Move the document to the new collection using a transaction
    late final Pair<DataWithId, String>? newUser;
    try {
      newUser = await _firestoreRepository.changeUserStorageType(
          userId,
          fromCollections
              .map(
                (name) => name.demoAwareCollectionName(
                  _authenticationService.isDemoUser,
                ),
              )
              .toList(),
          toCollection.demoAwareCollectionName(
            _authenticationService.isDemoUser,
          ),
          expectedCollectionName: expectedCollection
              ?.demoAwareCollectionName(_authenticationService.isDemoUser));
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
        case UserType.parent_type:
          return Pair(Parent.fromDataWithId(newUser.first), newType);
        case UserType.researcher_type:
          return Pair(Researcher.fromDataWithId(newUser.first), newType);
        default:
          throw ActionFailedException(
              "GeneralUserService: changeUserType() new type is invalid after the move. This should never happen.");
      }
    }
  }

  Future<bool> setPrivacyPolicyAccepted(String userId, bool accepted,
      {UserType? userType}) async {
    debugPrint(
        "GeneralUserService: setPrivacyPolicyAccepted() userId: $userId, accepted: $accepted");
    if (userType == null || userType == UserType.unauthenticated_type) {
      debugPrint(
          "GeneralUserService: setPrivacyPolicyAccepted() expectedType is null, getting user type");
      Pair<dynamic, UserType> user = await getUser(userId);
      if (user.first == null) {
        debugPrint(
            "GeneralUserService: setPrivacyPolicyAccepted() could not find user to determine type, returning false");
        return false; // user not found
      } else {
        userType = user.second;
        debugPrint(
            "GeneralUserService: setPrivacyPolicyAccepted() userType: ${userType.name}");
      }
    }

    switch (userType) {
      case UserType.parent_type:
        bool success = await _parentDataService.updateParent(
          userId,
          acceptedPrivacyPolicy: accepted,
          policyVersion: PrivacyPolicyInformation.privacyPolicyVersion,
          consentDate: DateTime.now(),
        );
        if (!success) {
          debugPrint(
              "GeneralUserService: setPrivacyPolicyAccepted() failed to update parent");
        }
        return success;
      case UserType.researcher_type:
        bool success = await _researcherDataService.updateResearcher(
          userId,
          acceptedPrivacyPolicy: accepted,
          policyVersion: PrivacyPolicyInformation.privacyPolicyVersion,
          consentDate: DateTime.now(),
        );
        if (!success) {
          debugPrint(
              "GeneralUserService: setPrivacyPolicyAccepted() failed to update researcher");
        }
        return success;
      default:
        debugPrint(
            "GeneralUserService: setPrivacyPolicyAccepted() could not find user to determine type, returning false");
        return false; // user not found
    }
  }
}

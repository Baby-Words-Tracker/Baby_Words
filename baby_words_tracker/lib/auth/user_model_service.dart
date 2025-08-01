import 'package:baby_words_tracker/auth/authentication_service.dart';

import 'package:baby_words_tracker/data/listeners/i_document_listener.dart';
import 'package:baby_words_tracker/data/models/i_user_model.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/data/services/general_user_service.dart';

import 'package:baby_words_tracker/util/pair.dart';
import 'package:baby_words_tracker/util/safe_synchronizer.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type.dart';

import 'package:flutter/material.dart';

class UserModelService extends ChangeNotifier {
  late final SafeSynchronizer _informationSynchronizer;

  static const UserType _defaultUserType = UserType.parent_type;

  final AuthenticationService _authenticationService;
  final GeneralUserService _generalUserService;

  IDocumentListener? _listener;

  int i = 0;
  int localI = 0;

  UserModelService({
    required AuthenticationService authenticationService,
    required GeneralUserService generalUserService,
  })  : _authenticationService = authenticationService,
        _generalUserService = generalUserService {
    _informationSynchronizer = SafeSynchronizer(_synchronizeUser);

    _authenticationService.addListener(() {
      debugPrint(
          "UserModelService: change notification recieved. resync triggered");
      _informationSynchronizer.safeSynchronize().catchError((e) {
        debugPrint(
            "UserModelService: Error synchronizing user: $e\n${e.stackTrace}");
        return;
      });
    });
  }

  Future<void> _synchronizeUser() async {
    int localI = ++i;
    debugPrint(
        "UserModelService: $localI: Synchronizing user: ${_authenticationService.userId}");
    try {
      // If the user is unauthenticated, dispose the listener and set userType to unauthenticated
      if (!_authenticationService.isAuthenticated ||
          _authenticationService.userId == null) {
        _unathenticateUser();
        debugPrint(
            "UserModelService: $localI: User unauthenticated ending synchronization.");
        return;
      }
      // else if the signed in user has changed, synchronize the user model
      else if (_getCurrentUserModelId() != _authenticationService.userId) {
        final targetUserId = _authenticationService.userId!;
        debugPrint(
            "UserModelService: $localI: ${_authenticationService.userType.displayName} user authenticated, but not synchronized (UserType: ${_authenticationService.userType})");

        UserType? listenedType = await _updateUserModelListener(targetUserId);

        // create a new user document if one does not exist
        if (listenedType == null) {
          debugPrint(
              "UserModelService: $localI: Creating new user -> email: ${_authenticationService.userEmail} | userName: ${_authenticationService.userName} | userType: ${_authenticationService.userType.name}");

          Pair<dynamic, UserType> user = await _generalUserService.createUser(
              userType: _authenticationService.userType,
              id: targetUserId,
              email: _authenticationService.userEmail,
              name: _authenticationService.userName);

          debugPrint(
              "UserModelService: $localI: user created -> ${user.first} | ${user.second}");
          if (user.first != null) {
            debugPrint("UserModelService: $localI: new User model created");
            listenedType = await _updateUserModelListener(targetUserId);
            if (user.second != _defaultUserType) {
              debugPrint(
                  "Warning: UserModelService: User type mismatch, expected $_defaultUserType, got ${user.second}");
            }
          } else {
            debugPrint("Error: UserModelService: Failed to create user");
          }
        } else {
          if (getCurrentUserModel() == null) {
            debugPrint(
                "Error: UserModelService: User model is null when the usertype is not unauthenticated");
          } else {
            debugPrint(
                "UserModelService: $localI: User Data synchronized successfully");
          }
        }
      } else {
        debugPrint(
            "UserModelService: $localI: User is already authenticated and synchronized, no action needed");
      }
    } catch (e, stack) {
      debugPrint(
          "UserModelService: $localI: _synchronizeUser failed: $e\n$stack");
    }
    debugPrint(
        "UserModelService: $localI: Synchronization finished, userType: ${_authenticationService.userType.name}");
  }

  IUserModel? getCurrentUserModel() {
    final data = _listener?.data;
    switch (_authenticationService.userType) {
      case UserType.parent_type:
        return data is Parent ? data : null;
      case UserType.researcher_type:
        return data is Researcher ? data : null;
      default:
        return null;
    }
  }

  String? _getCurrentUserModelId() {
    return getCurrentUserModel()?.id;
  }

  void _unathenticateUser() {
    _listener?.dispose();
    _listener = null;
    debugPrint(
        "UserModelService: User unauthenticated, listener disposed, notifying listeners");
    notifyListeners();
  }

  // TODO: fix this it is a nightmare. Its still kind of a nightmare but it works for now
  Future<UserType?> _updateUserModelListener(String userId) async {
    debugPrint("UserModelService: Updating user type and listener");
    // get a listener for the user model as well as the current user type in storage
    Pair<IDocumentListener?, UserType> listenerTypePair =
        await _generalUserService.getUserListener(userId,
            expectedListenerType: _authenticationService.userType);
    debugPrint(
        "UserModelService: ListenerTypePair: {${listenerTypePair.first} , ${listenerTypePair.second.name}}");

    // if the userType in the authentication service is different from the user's current storage in the database, we have an error
    if (_authenticationService.userType != listenerTypePair.second) {
      // TODO: add an actual logger that will log this so we can debug it and fix it
      debugPrint(
          "ERROR: UserModelService: User type mismatch, expected ${_authenticationService.userType.name}, got ${listenerTypePair.second.name}");
    }

    if (listenerTypePair.first == null) {
      debugPrint("User does not have an existing document. Returning null");
      _replaceListener(listenerTypePair.first, listenerTypePair.second);
      return null;
    }

    final currentUserModel = getCurrentUserModel();
    // TODO: update this equality ccheck to more accurately check equality
    //  (probably best to use some form of ID check instead of data equality along with a type check)
    if (currentUserModel == null ||
        listenerTypePair.first?.data == null ||
        listenerTypePair.first!.data.runtimeType !=
            currentUserModel.runtimeType ||
        listenerTypePair.first!.data != currentUserModel) {
      _replaceListener(listenerTypePair.first, listenerTypePair.second);
      return listenerTypePair.second;
    } else {
      debugPrint(
          "UserModelService: Listener already set to the correct user model, no need to replace");
      listenerTypePair.first!.dispose();
      return listenerTypePair.second;
    }
  }

  Future<void> _replaceListener(
      IDocumentListener? listener, UserType userType) async {
    debugPrint(
        "UserModelService: Replacing listener: listener: $listener, userType: $userType");

    if (listener != null) {
      debugPrint("UserModelService: Waiting for first document");
      await listener.waitForFirstDocument();
      debugPrint("UserModelService: First document received: ${listener.data}");
    }

    _listener?.dispose();
    _listener = listener;
    debugPrint("UserModelService: Listener replaced: $_listener.");

    // This line is important! This makes the class react to changes in the listener's data and notify its listeners.
    _listener?.addListener(() {
      if (_listener?.data == null) {
        _unathenticateUser();
        _informationSynchronizer.safeSynchronize().catchError((e) {
          debugPrint(
              "UserModelService: Error synchronizing user from listener callback: $e\n${e.stackTrace}");
        });
      }
      debugPrint(
          "UserModelService: Notifying listeners from listener callback");
      notifyListeners();
    });

    debugPrint("UserModelService: Listener replaced, notifying listeners");
    notifyListeners();
  }

  Parent? get parent {
    if (_authenticationService.userType != UserType.parent_type) {
      debugPrint("UserModelService: User is not a parent, returning null");
      return null;
    }
    return getCurrentUserModel() as Parent?;
  }

  Researcher? get researcher {
    if (_authenticationService.userType != UserType.researcher_type) {
      debugPrint("UserModelService: User is not a researcher, returning null");
      return null;
    }
    return getCurrentUserModel() as Researcher?;
  }

  Future<void> acceptPrivacyPolicy({bool accepted = true}) async {
    debugPrint("UserModelService: User accepted privacy policy");
    if (_authenticationService.userId == null) {
      debugPrint("UserModelService: User is not authenticated, cannot accept");
      return;
    }
    await _generalUserService.setPrivacyPolicyAccepted(
      _authenticationService.userId!,
      accepted,
      userType: _authenticationService.userType,
    );
  }
}

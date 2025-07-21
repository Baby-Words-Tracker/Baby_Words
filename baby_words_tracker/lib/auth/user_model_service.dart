import 'package:baby_words_tracker/auth/authentication_service.dart';

import 'package:baby_words_tracker/data/listeners/i_document_listener.dart';
import 'package:baby_words_tracker/data/models/i_user_model.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/data/services/general_user_service.dart';

import 'package:baby_words_tracker/util/pair.dart';
import 'package:baby_words_tracker/util/safe_synchronizer.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_role_and_type_mapper.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_roles.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type.dart';

import 'package:flutter/material.dart';

class UserModelService extends ChangeNotifier {
  late final SafeSynchronizer _informationSynchronizer;

  UserType _userType = UserType.unauthenticated;
  static const UserType _defaultUserType = UserType.parent;

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
      if (!_authenticationService.isAuthenticated ||
          _authenticationService.userId == null) {
        _unathenticateUser();
        debugPrint(
            "UserModelService: $localI: User unauthenticated ending synchronization.");
        return;
      }
      // else if user is marekd as unauthenticated or the signed in user has changed, synchronize user
      else if (_userType == UserType.unauthenticated ||
          _getCurrentUserModelId() != _authenticationService.userId) {
        debugPrint(
            "UserModelService: $localI: ${_userType.displayName} user authenticated, but not synchronized");

        await _updateUserTypeAndListener(_authenticationService.userId!);

        if (_userType == UserType.unauthenticated) {
          final customClaims = _authenticationService.customClaims;
          final List<UserRole> userRoles = customClaims != null
              ? getUserRolesFromClaims(customClaims)
              : [UserRole.unauthenticated];
          final maxRole = userRoles.reduce((a, b) => a.index < b.index ? a : b);
          final userType = maxRole.userType;

          debugPrint(
              "UserModelService: $localI: Creating new user -> email: ${_authenticationService.userEmail} | userName: ${_authenticationService.userName} | userType: ${userType.name}");

          Pair<dynamic, UserType> user = await _generalUserService.createUser(
              userType: userType,
              id: _authenticationService.userId!,
              email: _authenticationService.userEmail,
              name: _authenticationService.userName);

          debugPrint(
              "UserModelService: $localI: user created -> ${user.first} | ${user.second}");
          if (user.first != null) {
            debugPrint("UserModelService: $localI: new User model created");
            await _updateUserTypeAndListener(_authenticationService.userId!);
            if (user.second != _defaultUserType) {
              debugPrint(
                  "Error: UserModelService: User type mismatch, expected $_defaultUserType, got ${user.second}");
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
        "UserModelService: $localI: Synchronization finished, userType: ${_userType.name}");
  }

  IUserModel? getCurrentUserModel() {
    final data = _listener?.data;
    switch (_userType) {
      case UserType.parent:
        return data is Parent ? data : null;
      case UserType.researcher:
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
    _userType = UserType.unauthenticated;
    debugPrint(
        "UserModelService: User unauthenticated, listener disposed, userType set to $_userType, notifying listeners");
    notifyListeners();
  }

  Future<void> _updateUserTypeAndListener(String userId) async {
    debugPrint("UserModelService: Updating user type and listener");
    Pair<IDocumentListener?, UserType> listenerTypePair =
        await _generalUserService.getUserListener(userId,
            expectedListenerType: _userType);
    debugPrint(
        "UserModelService: ListenerTypePair: {${listenerTypePair.first} , ${listenerTypePair.second.name}}");
    if (_userType != listenerTypePair.second) {
      await _replaceListener(listenerTypePair.first, listenerTypePair.second);
    } else {
      final currentUserModel = getCurrentUserModel();
      if (listenerTypePair.first?.data?.runtimeType ==
              currentUserModel?.runtimeType &&
          listenerTypePair.first?.data != currentUserModel) {
        _replaceListener(listenerTypePair.first, listenerTypePair.second);
      }
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
    _userType = userType;
    debugPrint(
        "UserModelService: Listener replaced: $_listener, userType: $_userType");

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

  UserType get userType => _userType;

  Parent? get parent {
    if (_userType != UserType.parent) {
      debugPrint("UserModelService: User is not a parent, returning null");
      return null;
    }
    return getCurrentUserModel() as Parent?;
  }

  Researcher? get researcher {
    if (_userType != UserType.researcher) {
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
      userType: _userType,
    );
  }
}

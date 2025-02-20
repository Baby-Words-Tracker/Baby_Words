import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/util/pair.dart';
import 'package:baby_words_tracker/util/user_type.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';

import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/researcher_data_service.dart';
import 'package:baby_words_tracker/data/services/general_user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

class UserModelService extends ChangeNotifier {
  UserType _userType = UserType.unauthenticated;

  final ParentDataService _parentDataService;
  final ResearcherDataService _researcherDataService;
  final AuthenticationService _authenticationService;
  final GeneralUserService _generalUserService;

  Parent? _parent;
  Researcher? _researcher;

  bool _parentChanged = false;
  bool _researcherChanged = false;
  bool _isSynchronizing = false;

  UserModelService(
      {required ParentDataService parentDataService,
      required ResearcherDataService researcherDataService,
      required AuthenticationService authenticationService,
      required GeneralUserService generalUserService})
      : _parentDataService = parentDataService,
        _researcherDataService = researcherDataService,
        _authenticationService = authenticationService,
        _generalUserService = generalUserService {
    _parentDataService.addListener(() {
      _parentChanged = true;
      if (_userType == UserType.parent) {
        _refreshParent();
      }
      notifyListeners();
    });
    _researcherDataService.addListener(() {
      _researcherChanged = true;
      if (_userType == UserType.researcher) {
        _refreshResearcher();
      }
      notifyListeners();
    });
    _authenticationService.addListener(_synchronizeUser);
  }

  Future<void> _synchronizeUser() async {
    debugPrint("UserModelService: Synchronizing user: ${_authenticationService.userId}");
    if (_isSynchronizing) {
      return;
    }
    _isSynchronizing = true;
    
    try {
      if (!_authenticationService.isAuthenticated || _authenticationService.userId == null) {
        _unathenticateUser();
        debugPrint("UserModelService: User unauthenticated");
        return;
      } else if (_userType == UserType.unauthenticated ||
                _getCurrentUserModelId() != _authenticationService.userId ||  
                _getCurrentModelEmail() != _authenticationService.userEmail ||
                _getCurrentUserModelName() != _authenticationService.userName)
      {
        // debugPrint all of these and their comparison: _getCurrentModelEmail() != _authenticationService.userEmail || _getCurrentUserModelName() != _authenticationService.userName
        debugPrint("UserModelService: ${_userType.name} user authenticated, but not synchronized");

        await _fetchUserModel(_authenticationService.userId!);
        _researcherChanged = false;
        _parentChanged = false;

        if (_userType == UserType.unauthenticated) {
          // debugPrint("UserModelService: Creating new user -> email: ${_authenticationService.userEmail} | uaserName: ${_authenticationService.userName}");

          if (_authenticationService.userEmail == null) {
            debugPrint("Error: UserModelService: _synchronizeUser called with null email");
          }

          Pair<dynamic, UserType> user = await _generalUserService.createUser(
            userType: UserType.parent,
            id: _authenticationService.userId!,
            email: _authenticationService.userEmail,
            name: _authenticationService.userName
          );

          debugPrint("UserModelService: user created -> ${user.first} | ${user.second}");

          switch(user.second) {
            case UserType.parent:
              setUserParent(user.first);
              debugPrint("UserModelService: new Parent created");
              break;
            case UserType.researcher:
              setUserResearcher(user.first);
              debugPrint("UserModelService: new Researcher created");
              break;
            default:
              debugPrint("Error: UserModelService: Failed to create user");
              break;
          }
        }
        else {
          await _updateUserIfNecessary();
        }
      }
    } finally {
      _isSynchronizing = false;
    }
  }

  Future<void> _updateUserIfNecessary() async {
    switch (_userType) {
      case UserType.parent:
        if (_parent != null &&
            _parent!.id != _authenticationService.userId ||
            _parent!.email != _authenticationService.userEmail ||
            _parent!.name != _authenticationService.userName) {
          final success = await _parentDataService.updateParent(
              _parent!.id,
              email: _authenticationService.userEmail,
              name: _authenticationService.userName);
          
          if (success) {
            setUserParent(_parent!.copyWith(
                email: _authenticationService.userEmail,
                name: _authenticationService.userName));
          } else {
            debugPrint("Error: Failed to update parent in UserModelService");
            //TOOD: handle this error
          }
        }
        break;
      case UserType.researcher:
        if (_researcher!.email != _authenticationService.userEmail ||
            _researcher!.name != _authenticationService.userName) {
          bool success = await _researcherDataService.updateResearcher(
              _researcher!.id,
              email: _authenticationService.userEmail,
              name: _authenticationService.userName
          );

          if (success) {
            setUserResearcher(_researcher!.copyWith(
                email: _authenticationService.userEmail,
                name: _authenticationService.userName));
          } else {
            debugPrint(
                "Error: Failed to update researcher in UserModelService");
            //TOOD: handle this error
          }
        }
        break;
      default:
        break;
    }
  }

  void setUserParent(Parent parent) {
    if (_parent != parent) {
      _parent = parent;
      _userType = UserType.parent;
      notifyListeners();
    }
  }

  void setUserResearcher(Researcher researcher) {
    if (_researcher != researcher) {
      _researcher = researcher;
      _userType = UserType.researcher;
      notifyListeners();
    }
  }

  Future<void> _fetchUserModel(String userId) async {
    Pair<dynamic, UserType> user =
        await _generalUserService.getUser(userId, expectedType: _userType);

    if (user.second == UserType.parent) {
      setUserParent(user.first);
    } else if (user.second == UserType.researcher) {
      setUserResearcher(user.first);
    } else {
      _unathenticateUser();
    }
  }

  dynamic _getCurrentUserModel() {
    switch (_userType) {
      case UserType.parent:
        return _parent;
      case UserType.researcher:
        return _researcher;
      default:
        return null;
    }
  }

  String? _getCurrentModelEmail() {
    return _getCurrentUserModel()?.email;
  }

  String? _getCurrentUserModelName() {
    return _getCurrentUserModel()?.name;
  }

  String? _getCurrentUserModelId() {
    return _getCurrentUserModel()?.id;
  }

  void _unathenticateUser() {
    _userType = UserType.unauthenticated;
    _parent = null;
    _researcher = null;
    notifyListeners();
  }

  Future<void> _refreshParent() async {
    if (_parentChanged && _parent != null) {
      final newParent = await _parentDataService.getParent(_parent!.id);
      if (newParent != null) {
        _parent = newParent;
      } else {
        debugPrint("Error: Failed to refresh parent in UserModelService");
      }
      _parentChanged = false;
    }
  }

  Future<void> _refreshResearcher() async {
    if (_researcherChanged && _researcher != null) {
      final newResearcher = await _researcherDataService.getResearcher(_researcher!.id!);
      if (newResearcher != null) {
        _researcher = newResearcher;
      } else {
        debugPrint("Error: Failed to refresh researcher in UserModelService");
      }
      _researcherChanged = false;
    }
  }

  UserType get userType => _userType;

  Parent? get parent {
    return _parent;
  }

  Researcher? get researcher {
    return _researcher;
  }
}

import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/util/pair.dart';
import 'package:baby_words_tracker/util/user_type.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';

import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/researcher_data_service.dart';
import 'package:baby_words_tracker/data/services/general_user_service.dart';

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
      notifyListeners();
    });
    _researcherDataService.addListener(() {
      _researcherChanged = true;
      notifyListeners();
    });
    _authenticationService.addListener(_synchronizeUser);
  }

  Future<void> _synchronizeUser() async {
    debugPrint("UserModelService: Synchronizing user");

    if (!_authenticationService.isAuthenticated) {
      _unathenticateUser();
      debugPrint("UserModelService: User unauthenticated");
      return;
    } else if (_userType == UserType.unauthenticated ||
               _getCurrentModelEmail() == null || _getCurrentUserModelName() == null ||
                _getCurrentModelEmail() != (_authenticationService.userEmail ?? "") ||
               _getCurrentUserModelName() != (_authenticationService.userName ?? ""))
    {
      // debugPrint all of these and their comparison: _getCurrentModelEmail() != _authenticationService.userEmail || _getCurrentUserModelName() != _authenticationService.userName
      debugPrint("UserModelService: ${_userType.name} user authenticated, but not synchronized");

      await _fetchUserModelByEmail(_authenticationService.userEmail);

      if (_userType == UserType.unauthenticated) {
        // debugPrint("UserModelService: Creating new user -> email: ${_authenticationService.userEmail} | uaserName: ${_authenticationService.userName}");

        if (_authenticationService.userEmail == null) {
          debugPrint("Error: UserModelService: _synchronizeUser called with null email");
          return;
        }

        Pair<dynamic, UserType> user = await _generalUserService.createUser(
          _authenticationService.userEmail!, 
          _authenticationService.userName ?? "New User", 
          UserType.parent
        );

        debugPrint("UserModelService: user created -> ${user.first} | ${user.second}");

        if (user.second == UserType.parent) {
          setUserParent(user.first);
          debugPrint("UserModelService: new Parent created");
        } else if (user.second == UserType.researcher) {
          setUserResearcher(user.first);
          debugPrint("UserModelService: new Researcher created");
        } else {
          debugPrint("Error: UserModelService: Failed to create user");
        }
      }
      else {
        switch (_userType) {
          case UserType.parent:
            if (_parent!.email != _authenticationService.userEmail ||
                _parent!.name != _authenticationService.userName) {
              Parent? newParent = await _parentDataService.updateParentFromModel(
                  _parent!.copyWith(
                      email: _authenticationService.userEmail,
                      name: _authenticationService.userName));

              if (newParent != null) {
                setUserParent(newParent);
              } else {
                debugPrint("Error: Failed to update parent in UserModelService");
                //TOOD: handle this error
              }
            }
            break;
          case UserType.researcher:
            if (_researcher!.email != _authenticationService.userEmail ||
                _researcher!.name != _authenticationService.userName) {
              Researcher? newResearcher = await _researcherDataService
                  .updateResearcherFromModel(_researcher!.copyWith(
                      email: _authenticationService.userEmail,
                      name: _authenticationService.userName));

              if (newResearcher != null) {
                setUserResearcher(newResearcher);
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

  Future<void> _fetchUserModelByEmail(String? email) async {
    if (email == null) {
      debugPrint("Error: UserModelService: _fetchUserModelByEmail called with null email");
      _unathenticateUser();
      return;
    }

    Pair<dynamic, UserType> user =
        await _generalUserService.getUser(email, expectedType: _userType);

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

  void _unathenticateUser() {
    _userType = UserType.unauthenticated;
    _parent = null;
    _researcher = null;
    notifyListeners();
  }

  Future<void> _refreshParent() async {
    if (_parentChanged) {
      final newParent = await _parentDataService.getParent(_parent!.id!);
      if (newParent != null) {
        _parent = newParent;
      } else {
        debugPrint("Error: Failed to refresh parent in UserModelService");
      }
      _parentChanged = false;
    }
  }

  Future<void> _refreshResearcher() async {
    if (_researcherChanged) {
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

  Future<Parent?> get parent async {
    await _refreshParent();
    return _parent;
  }
  Future<Researcher?> get researcher async{
    await _refreshResearcher();
    return _researcher;
  }
}

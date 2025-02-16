
import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/util/user_type.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/models/researcher.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/researcher_data_service.dart';


import 'package:flutter/material.dart';

class UserModelService extends ChangeNotifier {
  UserType _userType = UserType.unauthenticated;
  
  ParentDataService _parentDataService;
  ResearcherDataService _researcherDataService;
  AuthenticationService _authenticationService;
  
  Parent? _parent;
  Researcher? _researcher;

  bool _parentChanged = false;
  bool _researcherChanged = false;

  UserModelService({
    required ParentDataService parentDataService, 
    required ResearcherDataService researcherDataService,
    required AuthenticationService authenticationService
  }) : _parentDataService = parentDataService, 
       _researcherDataService = researcherDataService,
       _authenticationService = authenticationService
  {
    _parentDataService.addListener(
      _setParentFlag
    );
    _researcherDataService.addListener(
      _setResearcherFlag
    );
    _authenticationService.addListener(
      _updateUser
    );
  }

  void _setParentFlag() {
    _parentChanged = true;
  }

  void _setResearcherFlag() {
    _researcherChanged = true;
  }

  Future<void> _updateUser() async {
    if (!_authenticationService.isAuthenticated) {
      _userType = UserType.unauthenticated;
      _parent = null;
      _researcher = null;

      notifyListeners();
      return;
    }
    else {
      await setUserByEmail(_authenticationService.userEmail);
      bool userChanged = false;
      await refreshUser();

      switch(userType) {
        case UserType.parent:
          if (_parent?.email != _authenticationService.userEmail) {
            await setUserByEmail(_authenticationService.userEmail);
            userChanged = true;
          }
          break;
        case UserType.researcher:
          if (_researcherChanged) {
            await _updateResearcher();
            userChanged = true;
          }
          break;
        default:
          break;
      }

    }
  }

  Future<void> refreshUser() async {
    _parentChanged = false;
    _researcherChanged = false;

    if (_userType == UserType.unauthenticated) {
      return;
    }
    else if (_userType == UserType.parent) {
      setUserParent(await _parentDataService.getParent(_parent!.email));
    } else if (_userType == UserType.researcher) {
      setUserResearcher(await _researcherDataService.getResearcher(_researcher!.email));
    }
  }

  Future<void> _updateParent() async {
    if (_parent == null) {
     _userType = UserType.unauthenticated;
    }
    else if (_userType == UserType.parent) {
      setUserParent(await _parentDataService.getParent(_parent!.email));
    }
    notifyListeners();
  }

  Future<void> _updateResearcher() async {
    if (_researcher == null) {
     _userType = UserType.unauthenticated;
    }
    else if (_userType == UserType.researcher) {
      setUserResearcher(await _researcherDataService.getResearcher(_researcher!.email));
    }
    notifyListeners();
  }

  void setUserParent(Parent? parent) {
    _parent = parent;
    if (parent == null) {
      _userType = UserType.unauthenticated;
    } else {
      _userType = UserType.parent;
    }
    notifyListeners();
  }

  void setUserResearcher(Researcher? researcher) {
    _userType = UserType.researcher;

    if (researcher == null) {
      _userType = UserType.unauthenticated;
    } else {
      _userType = UserType.researcher;
    }
    notifyListeners();
  }

  Future<void> setUserByEmail(String? email) async {
    if (email == null) {
      _userType = UserType.unauthenticated;
      notifyListeners();
      return;
    }

    Researcher? researcher = await _researcherDataService.getResearcher(email);
    if (researcher != null) {
      setUserResearcher(researcher);
      return;
    }

    Parent? parent = await _parentDataService.getParent(email);
    if (parent != null) {
      setUserParent(parent);
      return;
    }
  }


  dynamic getCurrentUserModel() {
    if (_userType == UserType.parent) {
      return _parent;
    } else if (_userType == UserType.researcher) {
      return _researcher;
    }
    return null;
  }

  UserType get userType => _userType;
  Parent? get parent => _parent;
  Researcher? get researcher => _researcher;
}
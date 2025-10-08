import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/auth/new_user_model_service.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/util/safe_synchronizer.dart';
import 'package:baby_words_tracker/util/user_type.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class CurrentChildrenService extends ChangeNotifier {
  late final SafeSynchronizer _parentSynchronizer;

  // Parent? _parent;
  List<Child> _children = List.empty(growable: true);
  int _childIndex = 0;
  bool _dataRetrieved = false;

  final UserModelService _userService;
  final NewUserModelService? _newUserService;
  final ChildDataService _childService;

  int getChildIndex() {
    return _childIndex;
  }

  CurrentChildrenService({
    required UserModelService userService,
    NewUserModelService? newUserService,
    required ChildDataService childService,
  })  : _userService = userService,
        _newUserService = newUserService,
        _childService = childService {
    _parentSynchronizer = SafeSynchronizer(() async {
      // Try new system first
      if (_newUserService != null) {
        final profile = _newUserService.userProfile;
        if (profile != null && profile.isParent && profile.childIDs.isNotEmpty) {
          return updateChildrenFromIds(profile.childIDs);
        }
      }
      
      // Fallback to old system
      Parent? parent = _userService.parent;
      if (_userService.userType != UserType.parent || parent == null) {
        _children.clear();
        _childIndex = 0;
        _dataRetrieved = false;
        notifyListeners();
        return Future.value();
      } else {
        return updateChildren(parent);
      }
    });
    _userService.addListener(_parentSynchronizer.safeSynchronize);
    _newUserService?.addListener(_parentSynchronizer.safeSynchronize);
  }

  List<Child>? getCurrChildren() {
    return _children;
  }

  Child? getCurrChild() {
    if (_children.isEmpty) {
      return null;
    }
    return _children[_childIndex];
  }

  Future<void> updateChildren(Parent parent) async {
    List<Child> children =
        (await _childService.getMultipleChildren(parent.childIDs));
    children.sortBy((child) => child.name);
    _children = children;
    _dataRetrieved = true;
    notifyListeners();
  }

  Future<void> updateChildrenFromIds(List<String> childIDs) async {
    if (childIDs.isEmpty) {
      _children.clear();
      _childIndex = 0;
      _dataRetrieved = false;
      notifyListeners();
      return;
    }
    
    List<Child> children = await _childService.getMultipleChildren(childIDs);
    children.sortBy((child) => child.name);
    _children = children;
    _dataRetrieved = true;
    notifyListeners();
  }

  void switchChild(String newChildID) {
    int i = 0;
    for (var child in _children) {
      if (child.id == newChildID) {
        _childIndex = i;
        notifyListeners();
        return;
      }
      i++;
    }
    notifyListeners();
  }

  void switchChildByIndex(int newChildIndex) {
    _childIndex = newChildIndex;
    notifyListeners();
  }

  bool get dataRetrieved {
    return _dataRetrieved;
  }
}

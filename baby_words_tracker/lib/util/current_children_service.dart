import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/type_aware_services/type_aware_child_data_service.dart';
import 'package:baby_words_tracker/util/safe_synchronizer.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class CurrentChildrenService extends ChangeNotifier {
  late final SafeSynchronizer _parentSynchronizer;

  // Parent? _parent;
  List<Child> _children = List.empty(growable: true);
  int _childIndex = 0;
  bool _dataRetrieved = false;

  final AuthenticationService _authenticationService;
  final UserModelService _userService;
  final TypeAwareChildDataService _childService;

  int getChildIndex() {
    return _childIndex;
  }

  CurrentChildrenService({
    required AuthenticationService authenticationService,
    required UserModelService userService,
    required TypeAwareChildDataService childService,
  })  : _authenticationService = authenticationService,
        _userService = userService,
        _childService = childService {
    _parentSynchronizer = SafeSynchronizer(() async {
      Parent? parent = _userService.parent;
      if (_authenticationService.userType != UserType.parent_type ||
          parent == null) {
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

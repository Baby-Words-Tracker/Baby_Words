import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/pages/testing/role_testing.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/safe_synchronizer.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/util/user_getters.dart';
import 'package:baby_words_tracker/util/user_type.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CurrentChildrenService extends ChangeNotifier {
  late final SafeSynchronizer _parentSynchronizer;

  // Parent? _parent;
  List<Child> _children = List.empty(growable: true);
  int _childIndex = 0;

  final UserModelService _userService;
  final ChildDataService _childService;

  int getChildIndex() {
    return _childIndex;
  }

  CurrentChildrenService({
    required UserModelService userService,
    required ChildDataService childService,
  })  : _userService = userService,
        _childService = childService {
    _parentSynchronizer = SafeSynchronizer(() async {
      Parent? parent =
          _userService.userType == UserType.parent ? _userService.parent : null;

      return updateChildren(parent);
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

  Future<void> updateChildren(Parent? parent) async {
    if (parent != null) // it could still be null after an updateparent
    {
      List<Child> children =
          (await _childService.getMultipleChildren(parent!.childIDs));
      children.sortBy((child) => child.name);
      _children = children;
    } else {
      _children = List.empty();
      _childIndex = 0;
    }
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
}

import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/util/user_getters.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CurrentChildrenService extends ChangeNotifier {
  Parent? _parent;
  List<Child> _children = List.empty(growable: true);
  int _childIndex = 0;

  int getChildIndex() {
    return _childIndex;
  }

  List<Child>? getCurrChildren(BuildContext context) {
    if (_children.isEmpty){
      updateChildren(context);
    }
    if (_parent == null){ // if the user isnt a parent yet, just return null
      return null;
    }
    if (_children.isEmpty) // if its still empty after an update, tell them to make a child
    {
      showAlertMessage(context, "No Children", "Please add a child in Settings."); // idfk if this is good practice man
      return null;
    }
    return _children;
  }

  Child? getCurrChild(BuildContext context) {
    if (_children.isEmpty){
      updateChildren(context);
    }
    if (_parent == null){ // if the user isnt a parent yet, just return null
      return null;
    }
    if (_children.isEmpty) // if its still empty after an update, tell them to make a child
    {
      //showAlertMessage(context, "No Children", "Please add a child in Settings."); // idfk if this is good practice man
      return null;
    }
    return _children[_childIndex];
  }

  void updateParent(BuildContext context) {
    Parent? currParent = getCurrentParent(context);
    if (currParent == null) {
      //handle it being null
    }
    _parent = currParent;
  }

  void updateChildren(BuildContext context) async {
    if (_parent == null)
    {
      updateParent(context);
    }
    if (_parent != null) // it could still be null after an updateparent
    {
      List<Child> children = (await context.read<ChildDataService>().getMultipleChildren(_parent!.childIDs));
      children.sortBy((child) => child.name);
      _children = children;
      notifyListeners();
    }
  }

  void switchChild(String newChildID) {
    int i = 0;
    for (var child in _children) {
      if (child.id == newChildID){
        _childIndex = i;
        return;
      }
    }
    notifyListeners();
  }

  void switchChildByIndex(int newChildIndex) {
    _childIndex = newChildIndex;
    notifyListeners();
  }
}
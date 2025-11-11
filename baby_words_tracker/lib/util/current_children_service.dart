import 'package:baby_words_tracker/auth/user_profile_model_service.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/util/safe_synchronizer.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class CurrentChildrenService extends ChangeNotifier {
  late final SafeSynchronizer _parentSynchronizer;

  List<Child> _children = List.empty(growable: true);
  int _childIndex = 0;
  bool _dataRetrieved = false;
  int _notifyCount = 0;
  DateTime? _lastNotifyTime;

  final UserProfileModelService _userProfileService;
  final ChildDataService _childService;

  int getChildIndex() {
    return _childIndex;
  }

  CurrentChildrenService({
    required UserProfileModelService userProfileService,
    required ChildDataService childService,
  })  : _userProfileService = userProfileService,
        _childService = childService {
    debugPrint("CurrentChildrenService: Initializing");
    _parentSynchronizer = SafeSynchronizer(() async {
      debugPrint("CurrentChildrenService: Starting synchronization");
      final profile = _userProfileService.userProfile;
      
      // No profile yet - user not authenticated
      if (profile == null || !profile.isParent) {
        debugPrint("CurrentChildrenService: No profile or not a parent, clearing children");
        _children.clear();
        _childIndex = 0;
        _dataRetrieved = false;
        final now = DateTime.now();
        final timeSinceLastNotify = _lastNotifyTime != null ? now.difference(_lastNotifyTime!).inMilliseconds : null;
        debugPrint("CurrentChildrenService: notifyListeners() #${++_notifyCount} - no profile (${timeSinceLastNotify}ms since last)");
        _lastNotifyTime = now;
        notifyListeners();
        return Future.value();
      }
      
      debugPrint("CurrentChildrenService: Profile found with ${profile.childIDs.length} children");
      
      // Profile exists but no children yet
      if (profile.childIDs.isEmpty) {
        debugPrint("CurrentChildrenService: No children in profile, setting empty state");
        _children.clear();
        _childIndex = 0;
        _dataRetrieved = true; // Empty is a valid state
        final now = DateTime.now();
        final timeSinceLastNotify = _lastNotifyTime != null ? now.difference(_lastNotifyTime!).inMilliseconds : null;
        debugPrint("CurrentChildrenService: notifyListeners() #${++_notifyCount} - empty children (${timeSinceLastNotify}ms since last)");
        _lastNotifyTime = now;
        notifyListeners();
        return Future.value();
      }
      
      // Load children from profile
      debugPrint("CurrentChildrenService: Loading children: ${profile.childIDs}");
      return updateChildrenFromIds(profile.childIDs);
    });
    
    // Listen to UserProfile changes
    debugPrint("CurrentChildrenService: Setting up listener for UserProfile changes");
    _userProfileService.addListener(_parentSynchronizer.safeSynchronize);
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

  Future<void> updateChildrenFromIds(List<String> childIDs) async {
    debugPrint("CurrentChildrenService: updateChildrenFromIds called with ${childIDs.length} IDs");
    
    if (childIDs.isEmpty) {
      debugPrint("CurrentChildrenService: Empty childIDs, clearing");
      _children.clear();
      _childIndex = 0;
      _dataRetrieved = false;
      final now = DateTime.now();
      final timeSinceLastNotify = _lastNotifyTime != null ? now.difference(_lastNotifyTime!).inMilliseconds : null;
      debugPrint("CurrentChildrenService: notifyListeners() #${++_notifyCount} - cleared (${timeSinceLastNotify}ms since last)");
      _lastNotifyTime = now;
      notifyListeners();
      return;
    }
    
    debugPrint("CurrentChildrenService: Fetching children from ChildDataService...");
    List<Child> children = await _childService.getMultipleChildren(childIDs);
    debugPrint("CurrentChildrenService: Received ${children.length} children");
    
    children.sortBy((child) => child.name);
    _children = children;
    
    // Ensure child index is within bounds after children list changes
    if (_childIndex >= _children.length) {
      _childIndex = _children.isNotEmpty ? 0 : 0;
    }
    
    _dataRetrieved = true;
    debugPrint("CurrentChildrenService: Children loaded successfully, notifying listeners");
    final now = DateTime.now();
    final timeSinceLastNotify = _lastNotifyTime != null ? now.difference(_lastNotifyTime!).inMilliseconds : null;
    debugPrint("CurrentChildrenService: notifyListeners() #${++_notifyCount} - children loaded (${timeSinceLastNotify}ms since last)");
    _lastNotifyTime = now;
    notifyListeners();
  }

  void switchChild(String newChildID) {
    int i = 0;
    for (var child in _children) {
      if (child.id == newChildID) {
        _childIndex = i;
        final now = DateTime.now();
        final timeSinceLastNotify = _lastNotifyTime != null ? now.difference(_lastNotifyTime!).inMilliseconds : null;
        debugPrint("CurrentChildrenService: notifyListeners() #${++_notifyCount} - switched to child $newChildID (${timeSinceLastNotify}ms since last)");
        _lastNotifyTime = now;
        notifyListeners();
        return;
      }
      i++;
    }
    final now = DateTime.now();
    final timeSinceLastNotify = _lastNotifyTime != null ? now.difference(_lastNotifyTime!).inMilliseconds : null;
    debugPrint("CurrentChildrenService: notifyListeners() #${++_notifyCount} - child $newChildID not found (${timeSinceLastNotify}ms since last)");
    _lastNotifyTime = now;
    notifyListeners();
  }

  void switchChildByIndex(int newChildIndex) {
    _childIndex = newChildIndex;
    final now = DateTime.now();
    final timeSinceLastNotify = _lastNotifyTime != null ? now.difference(_lastNotifyTime!).inMilliseconds : null;
    debugPrint("CurrentChildrenService: notifyListeners() #${++_notifyCount} - switched to index $newChildIndex (${timeSinceLastNotify}ms since last)");
    _lastNotifyTime = now;
    notifyListeners();
  }

  bool get dataRetrieved {
    return _dataRetrieved;
  }
}

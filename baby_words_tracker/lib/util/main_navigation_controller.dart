import 'package:flutter/material.dart';

/// Controls the primary bottom navigation selection for the parent shell.
class MainNavigationController extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void setIndex(int newIndex) {
    if (newIndex == _index) return;
    _index = newIndex;
    notifyListeners();
  }
}

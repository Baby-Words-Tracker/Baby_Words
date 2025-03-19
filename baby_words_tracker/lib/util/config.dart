import 'package:baby_words_tracker/util/language_code.dart';
import 'package:flutter/material.dart';

class Config extends ChangeNotifier {
  int _childIndex = 0;

  int get childIndex => _childIndex;

  void switchChild(int newChildIndex) {
    _childIndex = newChildIndex;
    notifyListeners();
  }
}
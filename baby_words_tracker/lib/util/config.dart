import 'package:baby_words_tracker/util/language_code.dart';
import 'package:flutter/material.dart';

class Config extends ChangeNotifier {
  int _childIndex = 0;
  LanguageCode _language = LanguageCode.en;

  int get childIndex => _childIndex;
  LanguageCode get language => _language; 

  void switchChild(int newChildIndex) {
    _childIndex = newChildIndex;
    notifyListeners();
  }

  void switchLanguage(LanguageCode newLanguage) {
    _language = newLanguage;
    notifyListeners(); 
  }
}
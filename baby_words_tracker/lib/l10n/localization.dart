import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:flutter/material.dart';


class Localization {
  final LanguageCode localeCode;
  final Locale locale; 
  late Map<String, String> _localizedStrings;

  Localization(this.localeCode, this.locale);

  Future<void> load() async {
    final jsonString = await rootBundle.loadString('assets/translation.json');
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

    _localizedStrings = jsonMap[localeCode.displayCode]?.cast<String, String>() ?? {};
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}
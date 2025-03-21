import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:baby_words_tracker/util/language_code.dart';

class Localization {
  final LanguageCode locale;
  late Map<String, String> _localizedStrings;

  Localization(this.locale);

  Future<void> load() async {
    final jsonString = await rootBundle.loadString('assets/translation.json');
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

    _localizedStrings = jsonMap[locale.displayCode]?.cast<String, String>() ?? {};
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}
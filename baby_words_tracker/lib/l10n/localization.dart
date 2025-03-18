import 'dart:convert';
import 'package:flutter/services.dart';

class Localization {
  final String locale;
  late Map<String, String> _localizedStrings;

  Localization(this.locale);

  Future<void> load() async {
    final jsonString =
        await rootBundle.loadString('assets/translation.json');
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    _localizedStrings =
        jsonMap[locale]?.cast<String, String>() ?? {};
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}
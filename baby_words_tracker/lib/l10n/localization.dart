import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/l10n/all_localizations.dart';
import 'package:flutter/material.dart';

class Localization {
  LanguageCode languageCode;
  Locale locale;
  //late Map<String, String> _localizedStrings;

  Localization(this.languageCode, this.locale);

  Future<void> setLocale(LanguageCode code) async {
    languageCode = code;
    locale = Locale(code.dartLocaleCode);
  }

  /*  Future<void> load() async {
    final jsonString = await rootBundle.loadString('assets/translation.json');
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString); //all strings 

    _localizedStrings = jsonMap[localeCode.dartLocaleCode]?.cast<String, String>() ?? {};
  } */

  String translate(String key) {
    return AllLocalizations
            .localizedStrings[languageCode.dartLocaleCode]![key] ??
        key;
  }
}

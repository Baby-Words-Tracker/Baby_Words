import 'package:baby_words_tracker/l10n/localization.dart';
import 'package:baby_words_tracker/util/language_code.dart';

import 'package:flutter/material.dart';

class LocalizationService with ChangeNotifier {
  late Localization _localization;

  Localization get localization => _localization;

  LocalizationService() {
    _localization = Localization(LanguageCode.en,
        const Locale('en')); //initially set to english changes based on user
    notifyListeners();
  }

  Future<void> changeLocale(LanguageCode locale) async {
    await _localization.setLocale(locale);
    notifyListeners();
  }

  String translate(String key) {
    return _localization.translate(key);
  }

  LanguageCode getLocaleCode() {
    return _localization.languageCode;
  }

  Locale getLocale() {
    return _localization.locale;
  }
}

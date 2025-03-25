import 'package:baby_words_tracker/l10n/localization.dart';
import 'package:baby_words_tracker/util/language_code.dart';

import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';

import 'package:baby_words_tracker/util/user_getters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:flutter/foundation.dart';

class LocalizationService with ChangeNotifier {
  late Localization _localization;

  Localization get localization => _localization;

  LocalizationService() {
    _localization = Localization(LanguageCode.en, const Locale('en')); //initially set to english changes based on user
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
    return _localization.localeCode; 
  }

  Locale getLocale() {
    return _localization.locale;
  }
}
import 'package:baby_words_tracker/l10n/localization.dart';
import 'package:baby_words_tracker/util/language_code.dart';

import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:flutter/foundation.dart';

class LocalizationService with ChangeNotifier {
  late Localization _localization;

  Localization get localization => _localization;

  LocalizationService() {
    _localization = Localization(LanguageCode.es); //initially set to english changes based on user
    _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    await _localization.load();
    notifyListeners();
  }

  Future<void> changeLocale(LanguageCode locale) async {
    _localization = Localization(locale);
    await _loadTranslations();
  }

}
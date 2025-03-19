import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/user_getters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/util/user_getters.dart';

Future<void> matchParentLanguage(BuildContext context) async {
  Parent? parent = getCurrentParent(context);
  if (parent != null) {
    final LanguageCode langauge = parent.language;
    LocalizationService localizationService = context.read<LocalizationService>();
    localizationService.changeLocale(langauge);
  }
  return;
}
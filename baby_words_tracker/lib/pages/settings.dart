import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/util/child_utils.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _AddSettingsPage();
}

class _AddSettingsPage extends State<SettingsPage> {
  final TextEditingController textcontroller1 = TextEditingController();
  final TextEditingController textcontroller2 = TextEditingController();
  final TextEditingController textcontroller3 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        bool _isSpanish =
            localizationService.getLocaleCode() == LanguageCode.es;
        return Scaffold(
            backgroundColor: Colors.white,
            appBar: TopBar(
              pageName:
                  localizationService.translate("settings"),
            ),
            bottomNavigationBar: bottomBar(context, "settings"),
            body: Center(
              child: Column(
                children: [
                  const SizedBox(
                    height: 70,
                  ),
                  Text(localizationService.translate("settings"),
                      style: const TextStyle(
                          fontSize: 32.0,
                          color: Color(0xFF9E1B32),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(
                    height: 60,
                  ),
                  childAddingFeature(context, textcontroller1, textcontroller2),
                  addCurrentChildToOtherParentFeature(context, textcontroller3),
                  Row(
                    //change language switch
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'English',
                        style: TextStyle(fontSize: 16),
                      ),
                      Switch(
                        value: _isSpanish,
                        onChanged: (value) {
                          setState(() {
                            late LanguageCode newLanguage;
                            if (_isSpanish) {
                              newLanguage = LanguageCode.en;
                            } else {
                              newLanguage = LanguageCode.es;
                            }
                            Parent parent = Provider.of<UserModelService>(
                                    context,
                                    listen: false)
                                .parent!;
                            Provider.of<ParentDataService>(context,
                                    listen: false)
                                .updateParent(parent.id, language: newLanguage);

                            ///localizationService.changeLocale(newLanguage);
                            _isSpanish = !_isSpanish;
                          });
                        },
                      ),
                      const Text(
                        'Español',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ));
      },
    );
  }
}

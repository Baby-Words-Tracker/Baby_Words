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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: TopBar(
          pageName: context.read<LocalizationService>().translate("settings"),
        ),
        bottomNavigationBar: BottomAppBar(
          color: const Color(0xFF9E1B32),
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 40.0,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/');
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outlined,
                      color: Colors.white,
                      size: 40.0,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/addtext');
                    },
                  ),
                  IconButton(
                      icon: const Icon(
                        Icons.video_camera_front,
                        color: Colors.white,
                        size: 40.0,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/uploadvideo');
                      }),
                  IconButton(
                    icon: const Icon(
                      Icons.bar_chart_outlined,
                      color: Colors.white,
                      size: 40.0,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/stats');
                    },
                  ),
                  const Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                    size: 40.0,
                  ),
                ],
              )),
        ),
        body: Consumer<LocalizationService>(
          builder: (context, localizationService, child) {
            bool _isSpanish = localizationService.getLocaleCode() == LanguageCode.es;
            return Center(
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
                  Row(
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
                  )
                ],
              ),
            );
          },
        ));
  }
}

import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/util/child_utils.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _AddSettingsPage();
}

class _AddSettingsPage extends State<SettingsPage> {
  final TextEditingController textcontroller1 = TextEditingController();
  final TextEditingController textcontroller2 = TextEditingController();
  final TextEditingController textcontroller3 = TextEditingController();
  List<LanguageCode> selectedLanguages = [LanguageCode.en];

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        bool _isSpanish =
            localizationService.getLocaleCode() == LanguageCode.es;
        return Scaffold(
            backgroundColor: Colors.white,
            appBar: TopBar(
              pageName: localizationService.translate("settings"),
            ),
            bottomNavigationBar: bottomBar(context, "settings"),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(
                  16.0), // Optional: Add some padding for better layout
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 25.0,
                  ),
                  Center(
                    child: Text(localizationService.translate("settings"),
                        style: const TextStyle(
                            fontSize: 32.0,
                            color: Color(0xFF9E1B32),
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(
                    height: 60,
                  ),
                  Text(localizationService.translate("parent_settings"),
                      style: const TextStyle(
                          fontSize: 27.0,
                          color: Color(0xFF9E1B32),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20.0),
                  Row(
                    //change language switch
                    children: [
                      Text(localizationService.translate("select_language"),
                          style: const TextStyle(
                            fontSize: 18.0,
                            color: Color(0xFF9E1B32),
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(width: 50.0),
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

                            localizationService.changeLocale(newLanguage);
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
                  const Divider(
                    color: Colors.grey, // Color of the divider
                    thickness: 1.0, // Thickness of the line
                    height: 40.0,
                  ),
                  childAddingFeature(context, textcontroller1, textcontroller2,
                      selectedLanguages),
                  const Divider(
                    color: Colors.grey, // Color of the divider
                    thickness: 1.0, // Thickness of the line
                    height: 40.0,
                  ),
                  addCurrentChildToOtherParentFeature(context, textcontroller3),
                ],
              ),
            ));
      },
    );
  }

  //needed this to be stateful to select language so moved out of child_util
  Consumer childAddingFeature(
      BuildContext context,
      TextEditingController nameController,
      TextEditingController dateController,
      List<LanguageCode> selectedLanguages) {
    return Consumer<LocalizationService>(
        builder: (context, localizationService, child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localizationService.translate("add_child"),
              style: const TextStyle(
                  fontSize: 27.0,
                  color: Color(0xFF9E1B32),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20.0),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              //border: OutlineInputBorder(),
              hintText: localizationService
                  .translate("choose_name"), //'Choose Name..',
              hintStyle: const TextStyle(color: Colors.white),
              filled: true,
              fillColor: const Color(0xFF9E1B32),
            ),
          ),
          const SizedBox(height: 20.0),
          TextField(
            controller: dateController,
            onTap: () => selectDate(context, dateController),
            readOnly: true,
            decoration: InputDecoration(
              //border: OutlineInputBorder(),
              hintText: localizationService
                  .translate("choose_birthday"), //'Tap to Choose Birthday..',
              hintStyle: const TextStyle(color: Colors.white),
              filled: true,
              fillColor: const Color(0xFF9E1B32),
            ),
          ),
          const SizedBox(height: 20.0),
          Text(localizationService.translate("select_language"),
              style: const TextStyle(
                fontSize: 18.0,
                color: Color(0xFF9E1B32),
                fontWeight: FontWeight.bold,
              )),
          CheckboxListTile(
            title: const Text("English"),
            value: selectedLanguages.contains(LanguageCode.en),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedLanguages.add(LanguageCode.en);
                } else if (selectedLanguages != [LanguageCode.en]) {
                  selectedLanguages.remove(LanguageCode.en);
                }
              });
            },
          ),
          CheckboxListTile(
            title: const Text("Español"),
            value: selectedLanguages.contains(LanguageCode.es),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedLanguages.add(LanguageCode.es);
                } else {
                  selectedLanguages.remove(LanguageCode.es);
                }
                if (selectedLanguages.isEmpty) {
                  selectedLanguages.add(LanguageCode.en);
                }
              });
            },
          ),
          const SizedBox(height: 20.0),
          Center(
              child: OutlinedButton(
            onPressed: () {
              if (nameController.text != "" &&
                  dateController.text !=
                      "") //add the word to the child with the id, or the default testing child if no input
              {
                //add child
                addChildToCurrParent(context, nameController.text,
                    DateTime.parse(dateController.text), selectedLanguages);
                //added indicator
                showAlertMessage(
                    context,
                    localizationService.translate("child_added"),
                    localizationService.translate(
                        "add_child_success")); //"Child Added!", "Successfully added your child!");
              } else {
                //failed to add indicator //FIXME: better error checking
                showAlertMessage(
                    context,
                    localizationService
                        .translate("child_not_added"), //"Child Add Failed",
                    localizationService.translate(
                        "add_child_failed")); //"Failed to add yoour child, please try again.");
              }
              nameController.clear();
              dateController.clear();
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFF828A8F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: const BorderSide(color: Colors.white, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
            ),
            child: Text(localizationService.translate("submit"),
                style: const TextStyle(fontSize: 18)),
          )),
        ],
      );
    });
  }
}

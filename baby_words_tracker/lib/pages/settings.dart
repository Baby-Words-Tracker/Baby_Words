import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/user_profile_service.dart';
import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/auth/user_profile_model_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/util/child_utils.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';

class SettingsPage extends StatefulWidget {
  static const routeName = '/settings';

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
        final theme = Theme.of(context);
        bool _isSpanish =
            localizationService.getLocaleCode() == LanguageCode.es;
        return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: TopBar(
              pageName: localizationService.translate("settings"),
            ),
            bottomNavigationBar: const CustomBottomBar(SettingsPage.routeName),
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
                    child: Text(
                      localizationService.translate("settings"),
                      style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700) ??
                          TextStyle(
                              fontSize: 32,
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(
                    height: 60,
                  ),
                  Text(
                    localizationService.translate("parent_settings"),
                    style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700) ??
                        TextStyle(
                            fontSize: 27,
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    //change language switch
                    children: [
                      Text(
                        localizationService.translate("select_language"),
                        style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600) ??
                            TextStyle(
                                fontSize: 18,
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 50.0),
                      Text(
                        'English',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Switch(
                        value: _isSpanish,
                        onChanged: (value) async {
                          late LanguageCode newLanguage;
                          if (_isSpanish) {
                            newLanguage = LanguageCode.en;
                          } else {
                            newLanguage = LanguageCode.es;
                          }
                          
                          // Try new system first
                          final userProfileModelService = Provider.of<UserProfileModelService>(
                              context, listen: false);
                          final userProfileService = Provider.of<UserProfileService>(
                              context, listen: false);
                          final userId = userProfileModelService.userProfile?.id;
                          
                          if (userId != null) {
                            // Update language preference in UserProfile
                            try {
                              await userProfileService.updateUserProfile(userId, {
                                'preferredLanguage': newLanguage.name,
                              });
                              debugPrint('Language changed to $newLanguage for user $userId');
                            } catch (e) {
                              debugPrint('Error updating language in UserProfile: $e');
                              // Try fallback to old system
                              try {
                                Parent parent = Provider.of<UserModelService>(
                                        context,
                                        listen: false)
                                    .parent!;
                                Provider.of<ParentDataService>(context,
                                        listen: false)
                                    .updateParent(parent.id, language: newLanguage);
                              } catch (e2) {
                                debugPrint('Fallback also failed: $e2');
                              }
                            }
                          } else {
                            // Fallback to old system
                            try {
                              Parent parent = Provider.of<UserModelService>(
                                      context,
                                      listen: false)
                                  .parent!;
                              Provider.of<ParentDataService>(context,
                                      listen: false)
                                  .updateParent(parent.id, language: newLanguage);
                            } catch (e) {
                              debugPrint('Error updating language in old system: $e');
                            }
                          }

                          localizationService.changeLocale(newLanguage);
                          setState(() {
                            _isSpanish = !_isSpanish;
                          });
                        },
                      ),
                      Text(
                        'Español',
                        style: theme.textTheme.bodyMedium,
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
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizationService.translate("add_child"),
            style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700) ??
                TextStyle(
                    fontSize: 27,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20.0),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: localizationService.translate("choose_name"),
              hintText: localizationService.translate("choose_name"),
            ),
          ),
          const SizedBox(height: 20.0),
          TextField(
            controller: dateController,
            onTap: () => selectDate(context, dateController),
            readOnly: true,
            decoration: InputDecoration(
              labelText: localizationService.translate("choose_birthday"),
              hintText: localizationService.translate("choose_birthday"),
              suffixIcon: Icon(
                Icons.calendar_today_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20.0),
          Text(
            localizationService.translate("select_language"),
            style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600) ??
                TextStyle(
                    fontSize: 18,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600),
          ),
          CheckboxListTile(
            title: Text(
              "English",
              style: theme.textTheme.bodyLarge,
            ),
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
            title: Text(
              "Español",
              style: theme.textTheme.bodyLarge,
            ),
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
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (nameController.text != "" && dateController.text != "") {
                  addChildToCurrParent(context, nameController.text,
                      DateTime.parse(dateController.text), selectedLanguages);
                  showAlertMessage(
                      context,
                      localizationService.translate("child_added"),
                      localizationService.translate("add_child_success"));
                } else {
                  showAlertMessage(
                      context,
                      localizationService.translate("child_not_added"),
                      localizationService.translate("add_child_failed"));
                }
                nameController.clear();
                dateController.clear();
              },
              child: Text(localizationService.translate("submit")),
            ),
          ),
        ],
      );
    });
  }
}

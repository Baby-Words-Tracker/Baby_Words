import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/auth/user_profile_model_service.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/user_profile.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/user_profile_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/child_utils.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  static const routeName = '/settings';

  final bool showChrome;

  const SettingsPage({super.key, this.showChrome = true});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _languageInitialised = false;
  late LanguageCode _selectedLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_languageInitialised) {
      _selectedLanguage = context.read<LocalizationService>().getLocaleCode();
      _languageInitialised = true;
    }
  }

  Future<void> _changeLanguage(LanguageCode newLanguage) async {
    if (_selectedLanguage == newLanguage) return;

    setState(() {
      _selectedLanguage = newLanguage;
    });

    final localizationService = context.read<LocalizationService>();
    final userProfileModelService = context.read<UserProfileModelService>();
    final userProfileService = context.read<UserProfileService>();
    final userModelService = context.read<UserModelService>();
    final parentDataService = context.read<ParentDataService>();

    final userId = userProfileModelService.userProfile?.id;
    final parentModel = userModelService.parent;

    if (userId != null) {
      try {
        await userProfileService.updateUserProfile(userId, {
          'preferredLanguage': newLanguage.name,
        });
      } catch (e) {
        debugPrint('Error updating language in UserProfile: $e');
        if (parentModel != null) {
          try {
            await parentDataService.updateParent(
              parentModel.id,
              language: newLanguage,
            );
          } catch (e2) {
            debugPrint('Fallback language update failed: $e2');
          }
        }
      }
    } else if (parentModel != null) {
      try {
        await parentDataService.updateParent(
          parentModel.id,
          language: newLanguage,
        );
      } catch (e) {
        debugPrint('Error updating language in legacy parent model: $e');
      }
    }

    await localizationService.changeLocale(newLanguage);
  }

  Future<void> _showAddChildSheet() async {
    final localization = context.read<LocalizationService>();
    final nameController = TextEditingController();
    DateTime? selectedBirthday;
    final Set<LanguageCode> selectedLanguages = {LanguageCode.en};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> pickBirthday() async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedBirthday ?? now,
                  firstDate: DateTime(now.year - 10),
                  lastDate: now,
                );
                if (picked != null) {
                  setModalState(() {
                    selectedBirthday = picked;
                  });
                }
              }

              void toggleLanguage(LanguageCode code) {
                setModalState(() {
                  if (selectedLanguages.contains(code)) {
                    if (selectedLanguages.length > 1) {
                      selectedLanguages.remove(code);
                    }
                  } else {
                    selectedLanguages.add(code);
                  }
                });
              }

              final birthdayLabel = selectedBirthday == null
                  ? localization.translate('choose_birthday')
                  : DateFormat.yMMMMd(
                      localization.localization.locale.toString(),
                    ).format(selectedBirthday!);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.translate('add_child'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: localization.translate('choose_name'),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    readOnly: true,
                    onTap: pickBirthday,
                    decoration: InputDecoration(
                      labelText: localization.translate('choose_birthday'),
                      hintText: localization.translate('choose_birthday'),
                      suffixIcon: const Icon(Icons.cake_outlined),
                    ),
                    controller: TextEditingController(text: birthdayLabel),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localization.translate('select_language'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('English'),
                        selected: selectedLanguages.contains(LanguageCode.en),
                        onSelected: (_) => toggleLanguage(LanguageCode.en),
                      ),
                      ChoiceChip(
                        label: const Text('Español'),
                        selected: selectedLanguages.contains(LanguageCode.es),
                        onSelected: (_) => toggleLanguage(LanguageCode.es),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty || selectedBirthday == null) {
                          await showAlertIfMounted(
                            context,
                            localization.translate('child_not_added'),
                            localization.translate('add_child_failed'),
                          );
                          return;
                        }

                        await addChildToCurrParent(
                          context,
                          name,
                          selectedBirthday!,
                          selectedLanguages.toList(),
                        );

                        if (!mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              localization.translate('child_added'),
                            ),
                          ),
                        );
                      },
                      child: Text(localization.translate('submit')),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showShareChildSheet() async {
    final localization = context.read<LocalizationService>();
    final currentChild = context.read<CurrentChildrenService>().getCurrChild();

    if (currentChild == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.translate('select_child')),
        ),
      );
      return;
    }

    final emailController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localization.translate('settings_share_child_title'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                localization.translate('settings_share_child_description'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: localization.translate('choose_email'),
                  prefixIcon: const Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty) {
                      await showAlertIfMounted(
                        context,
                        localization.translate('child_not_added'),
                        localization.translate('no_email'),
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    await addCurrentChildToOtherParent(context, email);
                  },
                  child: Text(localization.translate('submit')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<LocalizationService, UserProfileModelService,
        CurrentChildrenService>(
      builder: (context, localization, profileService, childrenService, _) {
        final theme = Theme.of(context);
        final profile = profileService.userProfile;
        final children = childrenService.getCurrChildren() ?? const <Child>[];
        final currentChildId = childrenService.getCurrChild()?.id;

        final content = SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              _ProfileCard(
                profile: profile,
                localization: localization,
              ),
              const SizedBox(height: 20),
              _LanguageCard(
                selectedLanguage: _selectedLanguage,
                onLanguageChanged: _changeLanguage,
                localization: localization,
              ),
              const SizedBox(height: 20),
              _ChildrenCard(
                children: children,
                currentChildId: currentChildId,
                localization: localization,
                onAddChild: _showAddChildSheet,
                onShareChild: _showShareChildSheet,
              ),
            ],
          ),
        );

        if (!widget.showChrome) {
          return content;
        }

        return Scaffold(
          appBar: TopBar(
            pageName: localization.translate('settings'),
          ),
          bottomNavigationBar: const CustomBottomBar(SettingsPage.routeName),
          body: content,
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.localization,
  });

  final UserProfile? profile;
  final LocalizationService localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : localization.translate('profile');
    final email = profile?.email ?? '—';
    final role = profile?.role.name ?? 'parent';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.translate('settings_profile_title'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                foregroundColor: theme.colorScheme.primary,
                child: Text(
                  name.characters.first.toUpperCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localization.translate('settings_primary_email_label')}: $email',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '${localization.translate('settings_role_label')}: ${role[0].toUpperCase()}${role.substring(1)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.localization,
  });

  final LanguageCode selectedLanguage;
  final ValueChanged<LanguageCode> onLanguageChanged;
  final LocalizationService localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.translate('settings_language_title'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<LanguageCode>(
              segments: const [
                ButtonSegment(
                  value: LanguageCode.en,
                  label: Text('English'),
                ),
                ButtonSegment(
                  value: LanguageCode.es,
                  label: Text('Español'),
                ),
              ],
              selected: {selectedLanguage},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  onLanguageChanged(selection.first);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildrenCard extends StatelessWidget {
  const _ChildrenCard({
    required this.children,
    required this.currentChildId,
    required this.localization,
    required this.onAddChild,
    required this.onShareChild,
  });

  final List<Child> children;
  final String? currentChildId;
  final LocalizationService localization;
  final VoidCallback onAddChild;
  final VoidCallback onShareChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMd(
      localization.localization.locale.toString(),
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.translate('settings_children_title'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  localization.translate('settings_no_children'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...children.map(
                (child) {
                  final isCurrent = child.id == currentChildId;
                  final languages =
                      child.language.map((code) => code.displayName).join(', ');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        width: isCurrent ? 1.2 : 1,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        child.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        [
                          dateFormat.format(child.birthday),
                          languages,
                        ].join(' • '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: isCurrent
                          ? Chip(
                              label: Text(
                                localization.translate('select_child'),
                              ),
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              labelStyle: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAddChild,
              icon: const Icon(Icons.add_rounded),
              label: Text(localization.translate('add_child')),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onShareChild,
              icon: const Icon(Icons.share_rounded),
              label: Text(
                localization.translate('settings_share_child_button'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

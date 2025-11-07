import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/auth/user_profile_model_service.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/user_profile.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/user_profile_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/profile_page.dart';
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

    final userId = userProfileModelService.userProfile?.id;

    if (userId != null) {
      try {
        await userProfileService.updateUserProfile(userId, {
          'preferredLanguage': newLanguage.name,
        });
      } catch (e) {
        debugPrint('Error updating language in UserProfile: $e');
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

  List<String> _getKnownChildIds() {
    final profile = context.read<UserProfileModelService>().userProfile;
    if (profile != null && profile.childIDs.isNotEmpty) {
      return List<String>.from(profile.childIDs);
    }
    final children = context.read<CurrentChildrenService>().getCurrChildren() ??
        const <Child>[];
    return children
        .where((child) => child.id != null)
        .map((child) => child.id!)
        .toList(growable: false);
  }

  Future<void> _showEditChildSheet(Child child) async {
    final localization = context.read<LocalizationService>();
    final theme = Theme.of(context);
    final rootContext = context;
    final nameController = TextEditingController(text: child.name);
    DateTime selectedBirthday = child.birthday;
    final Set<LanguageCode> selectedLanguages =
        child.language.isNotEmpty ? child.language.toSet() : {LanguageCode.en};
    bool isSaving = false;

    bool isSameDate(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> pickBirthday() async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: sheetContext,
                  initialDate: selectedBirthday,
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

              Future<void> handleSave() async {
                final trimmedName = nameController.text.trim();
                if (trimmedName.isEmpty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        localization.translate('settings_child_name_required'),
                      ),
                    ),
                  );
                  return;
                }

                final bool nameChanged = trimmedName != child.name;
                final bool birthdayChanged =
                    !isSameDate(selectedBirthday, child.birthday);
                final Set<LanguageCode> existingLanguages =
                    child.language.toSet();
                final bool languagesChanged =
                    !selectedLanguages.containsAll(existingLanguages) ||
                        !existingLanguages.containsAll(selectedLanguages);

                if (!nameChanged && !birthdayChanged && !languagesChanged) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        localization.translate('settings_child_no_changes'),
                      ),
                    ),
                  );
                  return;
                }

                if (child.id == null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        localization.translate('settings_child_update_failed'),
                      ),
                    ),
                  );
                  return;
                }

                setModalState(() => isSaving = true);

                try {
                  final success =
                      await context.read<ChildDataService>().updateChild(
                            child.id!,
                            name: nameChanged ? trimmedName : null,
                            birthday: birthdayChanged ? selectedBirthday : null,
                            language: languagesChanged
                                ? selectedLanguages.toList()
                                : null,
                          );
                  if (!success) {
                    throw Exception('child-update-failed');
                  }

                  await context
                      .read<CurrentChildrenService>()
                      .updateChildrenFromIds(_getKnownChildIds());

                  if (mounted) {
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          localization
                              .translate('settings_child_update_success'),
                        ),
                      ),
                    );
                    Navigator.of(sheetContext).pop();
                  }
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          localization
                              .translate('settings_child_update_failed'),
                        ),
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setModalState(() => isSaving = false);
                  }
                }
              }

              final birthdayLabel = DateFormat.yMMMMd(
                localization.localization.locale.toString(),
              ).format(selectedBirthday);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.translate('settings_edit_child_title'),
                    style: theme.textTheme.titleLarge?.copyWith(
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
                    style: theme.textTheme.titleSmall?.copyWith(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSaving
                            ? null
                            : () => Navigator.of(sheetContext).maybePop(),
                        child: Text(localization.translate('cancel')),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: isSaving ? null : handleSave,
                        child: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(localization.translate('save')),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteChild(Child child) async {
    final localization = context.read<LocalizationService>();
    if (child.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.translate('settings_child_delete_failed'),
          ),
        ),
      );
      return;
    }

    final confirmed = await showConfirmationDialog(
      context,
      localization
          .translate('settings_child_delete_confirm')
          .replaceFirst('{name}', child.name),
      title: localization.translate('confirm_action'),
    );

    if (!confirmed) {
      return;
    }

    final userProfileModelService = context.read<UserProfileModelService>();
    final userProfileService = context.read<UserProfileService>();
    final childDataService = context.read<ChildDataService>();

    final profileId = userProfileModelService.userProfile?.id;
    
    bool success = profileId != null;

    if (profileId != null) {
      success = await userProfileService.removeChild(profileId, child.id!);
      
      if (success) {
        await childDataService.removeParentFromChild(child.id!, profileId);
      }
    }

    if (success) {
      final updatedIds = _getKnownChildIds()..remove(child.id!);
      await context
          .read<CurrentChildrenService>()
          .updateChildrenFromIds(updatedIds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.translate('settings_child_delete_success'),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.translate('settings_child_delete_failed'),
            ),
          ),
        );
      }
    }
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
                onEditChild: _showEditChildSheet,
                onDeleteChild: _confirmDeleteChild,
                onSelectChild: (child) {
                  final id = child.id;
                  if (id != null) {
                    context.read<CurrentChildrenService>().switchChild(id);
                  }
                },
              ),
              const SizedBox(height: 20),
              _AccountManagementCard(
                localization: localization,
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
            const SizedBox(height: 8),
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
    required this.onEditChild,
    required this.onDeleteChild,
    required this.onSelectChild,
  });

  final List<Child> children;
  final String? currentChildId;
  final LocalizationService localization;
  final VoidCallback onAddChild;
  final VoidCallback onShareChild;
  final ValueChanged<Child> onEditChild;
  final ValueChanged<Child> onDeleteChild;
  final ValueChanged<Child> onSelectChild;

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
                  final bool hasId = child.id != null;
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
                      onTap: hasId ? () => onSelectChild(child) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCurrent)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Tooltip(
                                message: localization
                                    .translate('settings_current_child_label'),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            color: theme.colorScheme.primary,
                            tooltip: localization.translate('edit'),
                            onPressed: hasId ? () => onEditChild(child) : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: theme.colorScheme.error,
                            tooltip: localization.translate('delete'),
                            onPressed:
                                hasId ? () => onDeleteChild(child) : null,
                          ),
                        ],
                      ),
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

class _AccountManagementCard extends StatelessWidget {
  const _AccountManagementCard({
    required this.localization,
  });

  final LocalizationService localization;

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.translate('sign_out')),
        content: Text(
          localization.translate('settings_sign_out_confirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localization.translate('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localization.translate('sign_out')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthenticationService>().signOut();
    }
  }

  void _navigateToAccountDeletion(BuildContext context) {
    Navigator.of(context).pushNamed(ProfilePage.routeName);
  }

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
              localization.translate('settings_account_management_title'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmSignOut(context),
                icon: const Icon(Icons.logout_rounded),
                label: Text(localization.translate('sign_out')),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _navigateToAccountDeletion(context),
                icon: Icon(
                  Icons.delete_forever_rounded,
                  color: theme.colorScheme.error,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                label: Text(localization.translate('delete_account')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:baby_words_tracker/pages/auth_gate.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  static const routeName = '/profile';
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
        builder: (context, localizationService, child) {
      final theme = Theme.of(context);
      return ProfileScreen(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: Text(
            localizationService.translate("profile"),
            style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ) ??
                const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        actions: [
          SignedOutAction((context) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AuthGate.routeName, (route) => false);
          })
        ],
        showDeleteConfirmationDialog: true,
      );
    });
  }
}

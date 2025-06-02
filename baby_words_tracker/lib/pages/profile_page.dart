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
      return ProfileScreen(
        appBar: AppBar(
          title: Text(localizationService.translate("profile")),
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

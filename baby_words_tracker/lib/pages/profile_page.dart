import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
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
                .pushNamedAndRemoveUntil("/authgate", (route) => false);
          })
        ],
        showDeleteConfirmationDialog: true,
      );
    });
  }
}

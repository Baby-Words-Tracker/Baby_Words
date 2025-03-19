import 'package:baby_words_tracker/util/child_utils.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:baby_words_tracker/l10n/localization.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {

  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {

    final localizationService = context.read<LocalizationService>();
    var localization = localizationService.localization; 
    return ProfileScreen(
      appBar: AppBar(
          title: Text(localization.translate("profile")),
      ),
      actions: [
        SignedOutAction((context) {
          Navigator.of(context).pop();
        })
      ],
    );
  }
}
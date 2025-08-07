import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/pages/auth_gate.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  static const routeName = '/profile';
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationService, AuthenticationService>(
      builder: (
        context,
        localizationService,
        authenticationService,
        child,
      ) {
        if (authenticationService.user == null) {
          debugPrint("ProfilePage: User is null, navigating to AuthGate");
          return loadToNextPage(context, AuthGate.routeName);
        } else {
          return ProfileScreen(
            appBar: AppBar(
              title: Text(localizationService.translate("profile")),
            ),
            actions: [
              SignedOutAction((context) {
                debugPrint(
                    "ProfilePage: User signed out, navigating to AuthGate");
                Navigator.of(context).pushReplacementNamed(
                  AuthGate.routeName,
                  // (route) => false,
                );
              }),
              AccountDeletedAction((context, user) => Navigator.of(context)
                  .pushNamedAndRemoveUntil(
                      AuthGate.routeName, (route) => false)),
            ],
            showDeleteConfirmationDialog: true,
          );
        }
      },
    );
  }
}

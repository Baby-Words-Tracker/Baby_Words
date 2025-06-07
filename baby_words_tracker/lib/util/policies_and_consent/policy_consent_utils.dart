import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/util/policies_and_consent/privacy_policy_information.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> getUserConsent(BuildContext context) async {
    debugPrint("CustomBottomBar: Getting user consent");
    try {
      final hasAccepted = checkPrivacyPolicy(context);
      if (hasAccepted) {
        debugPrint(
            "CustomBottomBar: User has already accepted privacy policy, no action needed");
      } else {
        if (!context.mounted) {
          debugPrint(
              "CustomBottomBar: Context is not mounted, cannot show dialog");
          return;
        }
        debugPrint(
            "CustomBottomBar: User has not accepted privacy policy, prompting user");

        final bool? accepted = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Review Privacy Policy'),
              content: ConstrainedBox(
                constraints: BoxConstraints.loose(const Size(400, 300)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(PrivacyPolicyInformation.privacyPolicyText),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: GestureDetector(
                        onTap: () async {
                          const url = PrivacyPolicyInformation.privacyPolicyUrl;
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url),
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Deny'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Accept'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
              actionsAlignment: MainAxisAlignment.start,
            );
          },
        );
        if (accepted == true) {
          debugPrint(
              "CustomBottomBar: User accepted privacy policy, updating user model");
          if (!context.mounted) {
            debugPrint(
                "CustomBottomBar: Context is not mounted, cannot update user model");
            return;
          }
          final userModelService = context.read<UserModelService>();
          await userModelService.acceptPrivacyPolicy();
        } else {
          debugPrint(
              "CustomBottomBar: User did not accept privacy policy, logging out [need to fill this out]");
          if (!context.mounted) {
            debugPrint(
                "CustomBottomBar: Context is not mounted, cannot log out");
            return;
          }
          await context.read<AuthenticationService>().signOut();
        }
      }
    } catch (e, stack) {
      debugPrint(
          "CustomBottomBar: Error getting user consent: $e\n$stack");
    }
  }

  bool checkPrivacyPolicy(BuildContext context) {
    debugPrint("CustomBottomBar: Checking privacy policy");
    try {
      final currentUserModel =
          context.read<UserModelService>().getCurrentUserModel();
      if (currentUserModel != null) {
        final hasAccepted = currentUserModel.acceptedPrivacyPolicy;
        debugPrint(
            "CustomBottomBar: User ${currentUserModel.id} has accepted privacy policy: $hasAccepted");
        return hasAccepted;
      } else {
        debugPrint(
            "CustomBottomBar: User is not authenticated, returning true since no check is needed");
        return true;
      }
    } catch (e, stack) {
      debugPrint(
          "CustomBottomBar: Error checking privacy policy: $e\n$stack");
      return false;
    }
  }
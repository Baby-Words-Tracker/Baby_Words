import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/pages/display_video_page.dart';
import 'package:baby_words_tracker/pages/home_page.dart';
import 'package:baby_words_tracker/pages/settings.dart';
import 'package:baby_words_tracker/pages/stats.dart';
import 'package:baby_words_tracker/util/policies_and_consent/policy_consent_utils.dart';
import 'package:baby_words_tracker/util/safe_synchronizer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomBottomBar extends StatefulWidget {
  final String currPage;

  const CustomBottomBar(this.currPage, {super.key});
 
  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  static final _privacyPolicyCheckSynchronizer =
      SafeSynchronizer(getUserConsent, queueFunctionCalls: false);

  _CustomBottomBarState() : super() {
    debugPrint("CustomBottomBar: Initializing BottomBar");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userModelService = context.read<UserModelService>();
      userModelService.addListener(_consentListener);
      _consentListener(); // Initial check on creation
      debugPrint("CustomBottomBar: Listener added to UserModelService");
      debugPrint("CustomBottomBar: BottomBar initialized");
    });
  }

  @override
  void dispose() {
    debugPrint("CustomBottomBar: Disposing BottomBar");
    final userModelService = context.read<UserModelService>();
    userModelService.removeListener(_consentListener);
    super.dispose();
  }

  void _consentListener() {
    if (mounted) {
      debugPrint("CustomBottomBar: UserModelService listener triggered");
    } else {
      debugPrint(
          "CustomBottomBar: UserModelService listener triggered but context is not mounted");
      return;
    }
    _privacyPolicyCheckSynchronizer.safeSynchronize([context]).catchError((e) {
      debugPrint(
          "CustomBottomBar: Error checking privacy policy in callback: $e\n${e.stackTrace}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return createBottomBar(context, widget.currPage);
  }
}

// Bottom Bar Widget
// In its own file to save clutter
// Allows page name to be passed in to deactivate the button for the current page
Widget createBottomBar(BuildContext context, String currPage) {
  return BottomAppBar(
    color: const Color(0xFF9E1B32),
    child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.home,
                color: Colors.white,
                size: 40.0,
              ),
              onPressed: () {
                if (currPage != HomePage.routeName) {
                  Navigator.pushNamed(context, HomePage.routeName);
                }
              },
            ),
            IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.video_camera_front,
                  color: Colors.white,
                  size: 40.0,
                ),
                onPressed: () {
                  if (currPage != DisplayVideoPage.routeName) {
                    Navigator.pushNamed(context, DisplayVideoPage.routeName);
                  }
                }),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.bar_chart_outlined,
                color: Colors.white,
                size: 40.0,
              ),
              onPressed: () {
                if (currPage != StatsPage.routeName) {
                  Navigator.pushNamed(context, StatsPage.routeName);
                }
              },
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.settings_rounded,
                color: Colors.white,
                size: 40.0,
              ),
              onPressed: () {
                if (currPage != "settings") {
                  Navigator.pushNamed(context, SettingsPage.routeName);
                }
              },
            ),
          ],
        )),
  );
}

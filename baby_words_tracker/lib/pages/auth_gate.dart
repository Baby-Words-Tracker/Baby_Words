import 'dart:io' as io; // For checking platform
// import 'dart:ui';

import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/home_page.dart';
import 'package:baby_words_tracker/pages/researcher_home_page.dart';
import 'package:baby_words_tracker/util/policies_and_consent/policy_consent_utils.dart';
import 'package:baby_words_tracker/util/safe_synchronizer.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/util/user_types_and_roles/user_type.dart';

import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:provider/provider.dart';

// TODO: every account needs to be given the right type so it can get through this page
class AuthGate extends StatefulWidget {
  static const routeName = '/';
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static final _privacyPolicyCheckSynchronizer =
      SafeSynchronizer(getUserConsent, queueFunctionCalls: false);
  late final AuthenticationService _authenticationService;
  late final UserModelService _userModelService;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _authenticationService = Provider.of<AuthenticationService>(
        context,
        listen: false,
      );

      _userModelService = Provider.of<UserModelService>(
        context,
        listen: false,
      );
      _userModelService.addListener(_consentListener);

      _initialized = true;

      debugPrint("AuthGate: Listener added to UserModelService");
      debugPrint("AuthGate: AuthGate initialized");
    }
  }

  @override
  void dispose() {
    debugPrint("AuthGate: Disposing AuthGate");
    _userModelService.removeListener(_consentListener);
    super.dispose();
  }

  void _consentListener() {
    if (mounted) {
      debugPrint("AuthGate: UserModelService listener triggered");
    } else {
      debugPrint(
          "AuthGate: UserModelService listener triggered but context is not mounted");
      return;
    }

    _privacyPolicyCheckSynchronizer.safeSynchronize([
      context,
      _userModelService,
      _authenticationService,
    ]).catchError((e) {
      debugPrint(
          "AuthGate: Error checking privacy policy in callback: $e\n${e.stackTrace}");
      _authenticationService.signOut();
    });
  }

  String _getPlatformKey() {
    if (kIsWeb) {
      return '37552098276-cmotnbdu0toapp98j9duid91fuetlgg4.apps.googleusercontent.com'; // Use this key for web
    } else if (io.Platform.isIOS) {
      return '37552098276-0okgdbhghlc9di6svkvf7losu9esrp29.apps.googleusercontent.com'; // Use this key for iOS
    }
    return '37552098276-cmotnbdu0toapp98j9duid91fuetlgg4.apps.googleusercontent.com'; // Use this key for all other platforms
  }

  @override
  Widget build(BuildContext context) {
    var localizationService =
        Provider.of<LocalizationService>(context, listen: true);
    // TODO: this streambuilder might be a bit problematic.
    //  It listens to a similar stream to the one in AuthenticationService
    //  and then also listens to AuthentiationService. There is probably a
    //  better more robust way to do this.
    return StreamBuilder<User?>(
      stream: Provider.of<FirebaseAuth>(context).authStateChanges(),
      builder: (context, snapshot) {
        try {
          final authenticationService =
              Provider.of<AuthenticationService>(context, listen: true);
          final userModelService =
              Provider.of<UserModelService>(context, listen: true);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            String errorMessage = snapshot.error.toString();
            debugPrint("AuthGate: Stream error: $errorMessage");
            return Scaffold(
              body: Center(
                child: Text('An error occurred: $errorMessage'),
              ),
            );
          } else if (!snapshot.hasData ||
              snapshot.data == null ||
              !authenticationService.isAuthenticated ||
              !(checkPrivacyPolicy(userModelService, authenticationService) ??
                  false)) {
            return buildSignInScreen(
              context: context,
              localizationService: localizationService,
              authenticationService: authenticationService,
              platformKey: _getPlatformKey(),
            );
          }

          // Add user to database on first login
          User? user = snapshot.data;

          if (user == null) {
            debugPrint(
                'AuthGate: User is null despite hasData being true, redirecting to sign in');
            return buildSignInScreen(
              context: context,
              localizationService: localizationService,
              authenticationService: authenticationService,
              platformKey: _getPlatformKey(),
            );
          } else if (authenticationService.userType == UserType.parent_type) {
            debugPrint('AuthGate: User is a parent, navigating to HomePage');
            // add a frame callback to push the next route after the circular progress indicator is sown
            return loadToNextPage(
              context,
              HomePage.routeName,
            );
          } else if (authenticationService.userType ==
              UserType.researcher_type) {
            return loadToNextPage(
              context,
              ResearcherHomePage.routeName,
            );
          } else {
            debugPrint(
                'AuthGate: Unexpected user state occurred - userType: ${authenticationService.userType}, signing out');
            authenticationService.signOut();
            return buildSignInScreen(
              context: context,
              localizationService: localizationService,
              authenticationService: authenticationService,
              platformKey: _getPlatformKey(),
            );
          }
        } catch (e, stackTrace) {
          debugPrint(
              'AuthGate: Unexpected error in StreamBuilder: $e\n$stackTrace');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Authentication Error'),
                  const SizedBox(height: 8),
                  Text('$e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _authenticationService.signOut();
                    },
                    child: const Text('Sign Out and Retry'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

Widget buildSignInScreen({
  required BuildContext context,
  required LocalizationService localizationService,
  required AuthenticationService authenticationService,
  required String platformKey,
}) {
  return SignInScreen(
    providers: [
      EmailAuthProvider(),
      GoogleProvider(clientId: platformKey),
    ],
    headerBuilder: (context, constraints, shrinkOffset) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: AspectRatio(
          aspectRatio: 1,
          child: SvgPicture.asset(
            'assets/lecs_mascot_overlap.svg',
            fit: BoxFit.contain,
          ),
        ),
      );
    },
    subtitleBuilder: (context, action) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: action == AuthAction.signIn
            ? Text(localizationService.translate("welcome_sign_in"))
            : Text(localizationService.translate("welcome_sign_up")),
      );
    },
    footerBuilder: (context, action) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          context.read<LocalizationService>().translate("terms_and_conditions"),
          style: const TextStyle(color: Colors.grey),
        ),
      );
    },
    sideBuilder: (context, shrinkOffset) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: AspectRatio(
          aspectRatio: 1,
          child: SvgPicture.asset(
            'assets/lecs_mascot_overlap.svg',
            fit: BoxFit.contain,
          ),
        ),
      );
    },
  );
}

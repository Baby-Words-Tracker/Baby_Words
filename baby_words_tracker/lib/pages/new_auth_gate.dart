import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/auth/new_user_model_service.dart';
import 'package:baby_words_tracker/data/models/user_profile.dart';
import 'package:baby_words_tracker/pages/required_survey_page.dart';
import 'package:baby_words_tracker/util/policies_and_consent/policy_consent_utils.dart';
import 'package:baby_words_tracker/util/safe_synchronizer.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;

import 'researcher_home_page.dart';
import 'home_page.dart';

/// New AuthGate with UserProfile-based authentication
/// Includes platform enforcement and survey requirements
class NewAuthGate extends StatefulWidget {
  static const routeName = '/auth-gate';
  const NewAuthGate({super.key});

  @override
  State<NewAuthGate> createState() => _NewAuthGateState();
}

class _NewAuthGateState extends State<NewAuthGate> {
  static final _privacyPolicyCheckSynchronizer =
      SafeSynchronizer(getUserConsent, queueFunctionCalls: false);
  late final NewUserModelService _userModelService;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _userModelService = Provider.of<NewUserModelService>(context, listen: false);
      _userModelService.addListener(_consentListener);

      _initialized = true;

      debugPrint("NewAuthGate: Listener added to NewUserModelService");
      debugPrint("NewAuthGate: NewAuthGate initialized");
    }
  }

  @override
  void dispose() {
    debugPrint("NewAuthGate: Disposing NewAuthGate");
    _userModelService.removeListener(_consentListener);
    super.dispose();
  }

  void _consentListener() {
    if (!mounted) {
      debugPrint("NewAuthGate: Listener triggered but not mounted");
      return;
    }

    debugPrint("NewAuthGate: NewUserModelService listener triggered");

    // Only check privacy policy if user is fully authenticated and synced
    final userModelService = Provider.of<NewUserModelService>(context, listen: false);
    final authService = Provider.of<AuthenticationService>(context, listen: false);

    if (!authService.isAuthenticated) {
      debugPrint("NewAuthGate: User not authenticated, skipping privacy check");
      return;
    }

    if (!userModelService.isAuthenticated) {
      debugPrint("NewAuthGate: User profile not loaded, skipping privacy check");
      return;
    }

    _privacyPolicyCheckSynchronizer.safeSynchronize([context]).catchError((e) {
      debugPrint("NewAuthGate: Error checking privacy policy: $e\n${e.stackTrace}");
    });
  }

  String _getPlatformKey() {
    if (kIsWeb) {
      return '37552098276-cmotnbdu0toapp98j9duid91fuetlgg4.apps.googleusercontent.com';
    } else if (io.Platform.isIOS) {
      return '37552098276-0okgdbhghlc9di6svkvf7losu9esrp29.apps.googleusercontent.com';
    }
    return '37552098276-cmotnbdu0toapp98j9duid91fuetlgg4.apps.googleusercontent.com';
  }

  String _getCurrentPlatform() {
    return kIsWeb ? 'web' : 'mobile';
  }

  @override
  Widget build(BuildContext context) {
    var localizationService = Provider.of<LocalizationService>(context, listen: true);

    return StreamBuilder<User?>(
      stream: Provider.of<FirebaseAuth>(context).authStateChanges(),
      builder: (context, snapshot) {
        final userModelService = Provider.of<NewUserModelService>(context, listen: true);

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return _buildErrorScreen(context, snapshot.error.toString());
        }

        // Not authenticated - show sign in
        if (!snapshot.hasData) {
          return _buildSignInScreen(context, localizationService, _getPlatformKey());
        }

        // User is authenticated in Firebase Auth
        User? user = snapshot.data;

        // Still syncing user profile data
        if (!userModelService.isAuthenticated) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your profile...'),
                ],
              ),
            ),
          );
        }

        final profile = userModelService.userProfile!;

        debugPrint('NewAuthGate: Profile loaded - role: ${profile.role.name}, status: ${profile.status.name}');
        debugPrint('NewAuthGate: Privacy: ${profile.acceptedPrivacyPolicy}, Survey: ${profile.surveyCompleted}, Children: ${profile.childIDs.length}');

        // ==================== PLATFORM CHECK ====================
        final currentPlatform = _getCurrentPlatform();
        debugPrint('NewAuthGate: Platform check - current: $currentPlatform, can access: ${profile.canAccessPlatform(currentPlatform)}');
        if (!profile.canAccessPlatform(currentPlatform)) {
          return _buildPlatformMismatchScreen(context, profile, currentPlatform);
        }

        // ==================== PRIVACY POLICY CHECK ====================
        debugPrint('NewAuthGate: Privacy policy check - accepted: ${profile.acceptedPrivacyPolicy}');
        if (!profile.acceptedPrivacyPolicy) {
          // Privacy dialog will be shown by listener
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking privacy policy...'),
                ],
              ),
            ),
          );
        }

        // ==================== SURVEY CHECK (Parents only) ====================
        debugPrint('NewAuthGate: Survey check - requires: ${profile.requiresSurvey}, completed: ${profile.surveyCompleted}');
        if (profile.requiresSurvey) {
          return const RequiredSurveyPage();
        }

        // ==================== 2FA CHECK ====================
        // TODO: Implement 2FA flow when ready
        // For now, just log that it's required
        if (profile.requires2FA) {
          debugPrint('NewAuthGate: 2FA required for ${profile.id} (not yet implemented)');
          // Will add 2FA screen later
        }

        // ==================== ALL CHECKS PASSED ====================
        // Navigate to appropriate home screen based on role
        return Consumer<NewUserModelService>(
          builder: (context, userModelService, child) {
            if (user == null) {
              throw Exception('User is null in NewAuthGate');
            } else if (userModelService.isParent) {
              return const HomePage();
            } else if (userModelService.isResearcher || userModelService.isAdmin) {
              return const ResearcherHomePage();
            } else {
              throw Exception('Unexpected user role: ${profile.role.name}');
            }
          },
        );
      },
    );
  }

  Widget _buildSignInScreen(
    BuildContext context,
    LocalizationService localizationService,
    String platformKey,
  ) {
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

  Widget _buildPlatformMismatchScreen(
    BuildContext context,
    UserProfile profile,
    String currentPlatform,
  ) {
    String message;
    String suggestion;

    if (profile.isParent) {
      message = 'Parent accounts can only be accessed from the mobile app.';
      suggestion = 'Please download the mobile app to continue.';
    } else if (profile.isResearcher) {
      message = 'Researcher accounts can only be accessed from the web.';
      suggestion = 'Please visit our website to continue.';
    } else {
      message = 'Your account cannot be accessed from this platform.';
      suggestion = 'Please contact support for assistance.';
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.devices_other,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                'Wrong Platform',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                suggestion,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  Provider.of<AuthenticationService>(context, listen: false).signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'Authentication Error',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  Provider.of<AuthenticationService>(context, listen: false).signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out and Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


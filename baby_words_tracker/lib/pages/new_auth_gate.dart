import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/auth/onboarding_flow_manager.dart';
import 'package:baby_words_tracker/auth/tutorial_flow_manager.dart';
import 'package:baby_words_tracker/auth/user_profile_model_service.dart';
import 'package:baby_words_tracker/data/models/user_profile.dart';
import 'package:baby_words_tracker/pages/onboarding/email_verification_page.dart';
import 'package:baby_words_tracker/pages/onboarding/phone_verification_page.dart';
import 'package:baby_words_tracker/pages/onboarding/profile_info_page.dart';
import 'package:baby_words_tracker/pages/onboarding/privacy_policy_page.dart';
import 'package:baby_words_tracker/pages/onboarding/survey_page.dart';
import 'package:baby_words_tracker/pages/tutorial/welcome_page.dart';
import 'package:baby_words_tracker/pages/tutorial/add_first_child_page.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'researcher_home_page.dart';
import 'home_page.dart';
import 'parent_dashboard.dart';

/// New AuthGate with UserProfile-based authentication
/// Includes platform enforcement and survey requirements
class NewAuthGate extends StatefulWidget {
  static const routeName = '/auth-gate';
  const NewAuthGate({super.key});

  @override
  State<NewAuthGate> createState() => _NewAuthGateState();
}

class _NewAuthGateState extends State<NewAuthGate> {
  // Track tutorial progress locally to handle welcome screen completion
  bool _welcomeCompleted = false;
  
  @override
  void initState() {
    super.initState();
    debugPrint("NewAuthGate: Initialized with OnboardingFlowManager");
  }

  String _getCurrentPlatform() {
    return kIsWeb ? 'web' : 'mobile';
  }

  @override
  Widget build(BuildContext context) {
    var localizationService = Provider.of<LocalizationService>(context, listen: true);

    return StreamBuilder<User?>(
      // Use userChanges() instead of authStateChanges() to detect email verification
      // userChanges() fires when user properties change (email verified, display name, etc.)
      // authStateChanges() only fires on sign-in/sign-out
      stream: Provider.of<FirebaseAuth>(context).userChanges(),
      builder: (context, snapshot) {
        final userModelService = Provider.of<UserProfileModelService>(context, listen: true);

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
          return _buildSignInScreen(context, localizationService);
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

        // ==================== PLATFORM CHECK ====================
        final currentPlatform = _getCurrentPlatform();
        debugPrint('NewAuthGate: Platform check - current: $currentPlatform, can access: ${profile.canAccessPlatform(currentPlatform)}');
        if (!profile.canAccessPlatform(currentPlatform)) {
          return _buildPlatformMismatchScreen(context, profile, currentPlatform);
        }

        // ==================== ONBOARDING FLOW CHECK ====================
        // Use OnboardingFlowManager to determine which step user is on
        final onboardingStep = OnboardingFlowManager.getCurrentStep(
          firebaseUser: user,
          userProfile: profile,
        );
        
        debugPrint('NewAuthGate: Onboarding step: ${onboardingStep?.displayName ?? 'N/A'}');
        debugPrint(OnboardingFlowManager.getDebugStatus(
          firebaseUser: user,
          userProfile: profile,
        ));

        // Show appropriate onboarding screen based on current step
        switch (onboardingStep) {
          case OnboardingStep.profileInfo:
            return const ProfileInfoPage();
          
          case OnboardingStep.emailVerification:
            return const EmailVerificationPage();
          
          case OnboardingStep.phoneVerification:
            return const PhoneVerificationPage();
          
          case OnboardingStep.privacyPolicy:
            return const PrivacyPolicyPage();
          
          case OnboardingStep.survey:
            return const SurveyPage();
          
          case OnboardingStep.completed:
            // Onboarding complete - check if tutorial is needed
            break;
          
          case null:
            // Should not happen, but handle gracefully
            debugPrint('NewAuthGate: Warning - onboardingStep is null');
            break;
        }

        // ==================== TUTORIAL FLOW CHECK ====================
        // After onboarding, check if user needs tutorial (parents only)
        final needsTutorial = TutorialFlowManager.needsTutorial(profile);
        debugPrint('NewAuthGate: Needs tutorial: $needsTutorial, welcomeCompleted: $_welcomeCompleted');
        
        if (needsTutorial) {
          final tutorialStep = TutorialFlowManager.getCurrentStep(profile);
          debugPrint('NewAuthGate: Tutorial step: ${tutorialStep.displayName}');
          debugPrint(TutorialFlowManager.getDebugStatus(profile));
          
          // Show welcome screen first (if not already completed)
          if (!_welcomeCompleted) {
            return WelcomePage(
              onComplete: () {
                setState(() {
                  _welcomeCompleted = true;
                });
              },
            );
          }
          
          // After welcome, show add first child
          return const AddFirstChildPage();
          // When child is added, TutorialFlowManager.needsTutorial() will return false
          // and user will proceed to home page
        }

        // ==================== ALL CHECKS PASSED ====================
        // Navigate to appropriate home screen based on role
        if (user == null) {
          throw Exception('User is null in NewAuthGate');
        } else if (userModelService.isParent) {
          return const ParentDashboard();
        } else if (userModelService.isResearcher || userModelService.isAdmin) {
          return const ResearcherHomePage();
        } else {
          throw Exception('Unexpected user role: ${profile.role.name}');
        }
      },
    );
  }

  Widget _buildSignInScreen(
    BuildContext context,
    LocalizationService localizationService,
  ) {
    return SignInScreen(
      providers: [
        EmailAuthProvider(),
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
      message = 'Parents use the Baby Words mobile app to manage their account.';
      suggestion =
          'Download the mobile app to continue. If you are a researcher, contact support so we can authorize web access.';
    } else if (profile.isResearcher) {
      message = 'Researcher dashboards are only available on the web.';
      suggestion =
          'Please contact support to confirm your researcher authorization or try signing in from a desktop browser.';
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

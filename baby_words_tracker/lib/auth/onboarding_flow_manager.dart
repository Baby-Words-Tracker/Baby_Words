import 'package:baby_words_tracker/data/models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Defines the sequence of onboarding steps for new users
/// This makes it easy to add, remove, or reorder steps
enum OnboardingStep {
  profileInfo,
  emailVerification,
  phoneVerification,  // 2FA setup
  privacyPolicy,
  survey,
  completed;
  
  String get displayName {
    switch (this) {
      case OnboardingStep.profileInfo:
        return 'Profile Details';
      case OnboardingStep.emailVerification:
        return 'Email Verification';
      case OnboardingStep.phoneVerification:
        return 'Phone Verification';
      case OnboardingStep.privacyPolicy:
        return 'Privacy Policy';
      case OnboardingStep.survey:
        return 'Research Survey';
      case OnboardingStep.completed:
        return 'Completed';
    }
  }
  
  IconData get icon {
    switch (this) {
      case OnboardingStep.profileInfo:
        return Icons.person_outline;
      case OnboardingStep.emailVerification:
        return Icons.email_outlined;
      case OnboardingStep.phoneVerification:
        return Icons.phone_outlined;
      case OnboardingStep.privacyPolicy:
        return Icons.policy_outlined;
      case OnboardingStep.survey:
        return Icons.assignment_outlined;
      case OnboardingStep.completed:
        return Icons.check_circle_outline;
    }
  }
}

/// Centralized manager for the onboarding flow
/// Determines which step the user should see based on their profile and auth state
class OnboardingFlowManager {
  static const bool _requirePhoneVerification = false;

  static List<OnboardingStep> _activeStepsFor(UserProfile profile) {
    final steps = <OnboardingStep>[
      OnboardingStep.profileInfo,
      OnboardingStep.emailVerification,
      if (_requirePhoneVerification) OnboardingStep.phoneVerification,
      OnboardingStep.privacyPolicy,
      if (profile.isParent && profile.requiresSurvey) OnboardingStep.survey,
      OnboardingStep.completed,
    ];
    return steps;
  }

  /// Get the current onboarding step for a user
  /// Returns null if user is not authenticated or no profile exists
  static OnboardingStep? getCurrentStep({
    required User? firebaseUser,
    required UserProfile? userProfile,
  }) {
    // No user = not in onboarding
    if (firebaseUser == null || userProfile == null) {
      return null;
    }
    
    // Collect required profile info for all users
    final needsFirstName =
        userProfile.firstName == null || userProfile.firstName!.isEmpty;
    final needsLastName =
        userProfile.lastName == null || userProfile.lastName!.isEmpty;
    if (needsFirstName || needsLastName) {
      return OnboardingStep.profileInfo;
    }
    
    // All roles must verify email
    if (!firebaseUser.emailVerified) {
      return OnboardingStep.emailVerification;
    }
    
    // Optional phone verification / 2FA setup
    if (_requirePhoneVerification && !userProfile.twoFactorEnabled) {
      return OnboardingStep.phoneVerification;
    }
    
    // Everyone must accept privacy policy
    if (!userProfile.acceptedPrivacyPolicy) {
      return OnboardingStep.privacyPolicy;
    }
    
    // Only parents must complete research survey
    if (userProfile.isParent && userProfile.requiresSurvey) {
      return OnboardingStep.survey;
    }
    
    // All steps completed!
    return OnboardingStep.completed;
  }
  
  /// Check if user has completed all onboarding steps
  static bool isOnboardingComplete({
    required User? firebaseUser,
    required UserProfile? userProfile,
  }) {
    final step = getCurrentStep(
      firebaseUser: firebaseUser,
      userProfile: userProfile,
    );
    return step == OnboardingStep.completed;
  }
  
  /// Get the next step after the current one
  static OnboardingStep? getNextStep(OnboardingStep current) {
    final steps = OnboardingStep.values;
    final currentIndex = steps.indexOf(current);
    
    if (currentIndex < 0 || currentIndex >= steps.length - 1) {
      return null; // No next step
    }
    
    return steps[currentIndex + 1];
  }
  
  /// Get progress through onboarding (0.0 to 1.0)
  static double getProgress({
    required User? firebaseUser,
    required UserProfile? userProfile,
  }) {
    if (userProfile == null) return 0.0;

    final currentStep = getCurrentStep(
      firebaseUser: firebaseUser,
      userProfile: userProfile,
    );
    
    if (currentStep == null) return 0.0;
    if (currentStep == OnboardingStep.completed) return 1.0;
    
    final activeSteps = _activeStepsFor(userProfile);
    final totalSteps = activeSteps.length - 1;
    final currentIndex = activeSteps.indexOf(currentStep);

    if (currentIndex < 0 || totalSteps <= 0) {
      return 0.0;
    }
    
    return currentIndex / totalSteps;
  }
  
  /// Get all steps that have been completed
  static List<OnboardingStep> getCompletedSteps({
    required User? firebaseUser,
    required UserProfile? userProfile,
  }) {
    if (userProfile == null) return [];

    final currentStep = getCurrentStep(
      firebaseUser: firebaseUser,
      userProfile: userProfile,
    );
    
    if (currentStep == null) return [];
    
    final activeSteps = _activeStepsFor(userProfile);
    final currentIndex = activeSteps.indexOf(currentStep);

    if (currentIndex <= 0) {
      return [];
    }

    return activeSteps.sublist(0, currentIndex);
  }
  
  /// Debug string showing current state
  static String getDebugStatus({
    required User? firebaseUser,
    required UserProfile? userProfile,
  }) {
    final step = getCurrentStep(
      firebaseUser: firebaseUser,
      userProfile: userProfile,
    );
    final progress = getProgress(
      firebaseUser: firebaseUser,
      userProfile: userProfile,
    );
    
    return 'OnboardingFlow: Step=${step?.displayName ?? 'N/A'}, Progress=${(progress * 100).toStringAsFixed(0)}%';
  }
}

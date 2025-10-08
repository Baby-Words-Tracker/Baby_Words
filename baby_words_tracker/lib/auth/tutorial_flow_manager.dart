import 'package:baby_words_tracker/data/models/user_profile.dart';
import 'package:flutter/material.dart';

/// Tutorial/Welcome flow steps for new users
/// Happens AFTER onboarding (email, phone, privacy, survey) is complete
enum TutorialStep {
  welcome,
  addFirstChild,
  completed;
  
  String get displayName {
    switch (this) {
      case TutorialStep.welcome:
        return 'Welcome';
      case TutorialStep.addFirstChild:
        return 'Add First Child';
      case TutorialStep.completed:
        return 'Completed';
    }
  }
  
  IconData get icon {
    switch (this) {
      case TutorialStep.welcome:
        return Icons.waving_hand;
      case TutorialStep.addFirstChild:
        return Icons.child_care;
      case TutorialStep.completed:
        return Icons.check_circle_outline;
    }
  }
}

/// Manages the tutorial/welcome flow for new users
/// This is separate from onboarding (which handles verification/compliance)
class TutorialFlowManager {
  /// Check if user needs to see tutorial
  /// Tutorial is shown to parents who have completed onboarding but have no children
  static bool needsTutorial(UserProfile? userProfile) {
    if (userProfile == null) return false;
    
    // Only parents get tutorial
    if (!userProfile.isParent) return false;
    
    // Tutorial is needed if user has no children
    // Once they add a child, tutorial is complete
    return userProfile.childIDs.isEmpty;
  }
  
  /// Get the current tutorial step
  static TutorialStep getCurrentStep(UserProfile? userProfile) {
    if (userProfile == null) return TutorialStep.completed;
    
    // If user has children, tutorial is complete
    if (userProfile.childIDs.isNotEmpty) {
      return TutorialStep.completed;
    }
    
    // For now, we'll use a simple flow:
    // - If no children, show welcome then add child
    // - In future, we can track tutorial progress in UserProfile
    
    // This could be expanded with a tutorialCompleted field in UserProfile
    // For now, we assume if they have no children, they need the full tutorial
    return TutorialStep.welcome;
  }
  
  /// Check if tutorial is complete
  static bool isTutorialComplete(UserProfile? userProfile) {
    return getCurrentStep(userProfile) == TutorialStep.completed;
  }
  
  /// Get progress through tutorial (0.0 to 1.0)
  static double getProgress(UserProfile? userProfile) {
    final step = getCurrentStep(userProfile);
    
    if (step == TutorialStep.completed) return 1.0;
    if (step == TutorialStep.welcome) return 0.0;
    if (step == TutorialStep.addFirstChild) return 0.5;
    
    return 0.0;
  }
  
  /// Get next step
  static TutorialStep? getNextStep(TutorialStep current) {
    switch (current) {
      case TutorialStep.welcome:
        return TutorialStep.addFirstChild;
      case TutorialStep.addFirstChild:
        return TutorialStep.completed;
      case TutorialStep.completed:
        return null;
    }
  }
  
  /// Debug string
  static String getDebugStatus(UserProfile? userProfile) {
    final step = getCurrentStep(userProfile);
    final progress = getProgress(userProfile);
    
    return 'TutorialFlow: Step=${step.displayName}, Progress=${(progress * 100).toStringAsFixed(0)}%';
  }
}


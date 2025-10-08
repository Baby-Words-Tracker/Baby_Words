# Tutorial Flow Guide

**Created:** October 8, 2025  
**Status:** ✅ Complete  
**Version:** 1.0

---

## 🎯 Overview

The Tutorial Flow is a **separate, guided onboarding experience** that happens AFTER the compliance onboarding is complete. It introduces new users to the app features and helps them get started.

### **Two Separate Flows:**

1. **Onboarding Flow** (Compliance & Verification)
   - Email verification ✉️
   - Phone verification (2FA) 📱
   - Privacy policy acceptance 📜
   - Research survey 📊
   - **Purpose:** Account security & research compliance

2. **Tutorial Flow** (App Introduction) ⭐ **NEW!**
   - Welcome to WordBuds 👋
   - Add first child 👶
   - **Purpose:** Feature introduction & getting started

---

## 📋 Tutorial Steps

### **Step 1: Welcome Screen**
- Shows WordBuds mascot/logo
- Brief introduction to the app
- Highlights key features:
  - Track multiple children
  - Record words and milestones
  - View progress and insights
- "Get Started" button

### **Step 2: Add First Child**
- Guided child creation form
- Fields:
  - **Name** (required)
  - **Birthday** (date picker)
  - **Primary Language(s)** (multi-select chips)
- Helpful tips and information
- "Add Child & Continue" button

### **Step 3: Main App**
- Tutorial automatically completes when first child is added
- User proceeds to home page
- Can add more children later in Settings

---

## 🏗️ Architecture

### **Core Components**

#### 1. **TutorialFlowManager** (`lib/auth/tutorial_flow_manager.dart`)

Manages tutorial state and progression:

```dart
// Check if user needs tutorial
bool needsTutorial = TutorialFlowManager.needsTutorial(userProfile);

// Get current step
TutorialStep currentStep = TutorialFlowManager.getCurrentStep(userProfile);

// Check if complete
bool isComplete = TutorialFlowManager.isTutorialComplete(userProfile);
```

**Logic:**
- Tutorial is needed if user is a **parent** with **no children**
- Once user adds a child → tutorial complete
- Non-parents (researchers, admins) skip tutorial

#### 2. **TutorialStep Enum**

```dart
enum TutorialStep {
  welcome,        // Welcome screen
  addFirstChild,  // Add first child
  completed;      // Tutorial done
}
```

#### 3. **Tutorial Pages**

**WelcomePage** (`lib/pages/tutorial/welcome_page.dart`)
- Beautiful welcome screen
- Shows app features
- Callback when user clicks "Get Started"

**AddFirstChildPage** (`lib/pages/tutorial/add_first_child_page.dart`)
- Simplified child creation form
- Uses existing `addChildToCurrParent()` function
- Automatically completes tutorial when child is added

#### 4. **AuthGate Integration**

The `NewAuthGate` now checks for tutorial after onboarding:

```dart
// 1. Check onboarding (email, phone, privacy, survey)
if (onboarding not complete) {
  return OnboardingPage();
}

// 2. Check tutorial (welcome, add child)
if (tutorial needed) {
  if (!welcomeCompleted) {
    return WelcomePage();
  }
  return AddFirstChildPage();
}

// 3. All done!
return HomePage();
```

---

## 🔄 Flow Logic

### **How Tutorial Determines Completion**

```dart
static bool needsTutorial(UserProfile? userProfile) {
  if (userProfile == null) return false;
  
  // Only parents get tutorial
  if (!userProfile.isParent) return false;
  
  // Tutorial needed if user has no children
  return userProfile.childIDs.isEmpty;
}
```

**This means:**
- ✅ New parent with 0 children → Shows tutorial
- ✅ Parent with 1+ children → Skips tutorial (already knows the app)
- ✅ Researcher/Admin → Skips tutorial (different workflow)

### **Welcome Screen Flow**

Uses local state in `AuthGate` to track progression:

1. User completes onboarding
2. `needsTutorial()` returns `true`
3. Shows `WelcomePage`
4. User clicks "Get Started"
5. Sets `_welcomeCompleted = true`
6. Rebuilds and shows `AddFirstChildPage`

### **Add Child Flow**

1. User fills in child details (name, birthday, languages)
2. User clicks "Add Child & Continue"
3. Calls `addChildToCurrParent()` to create child
4. Child ID added to `UserProfile.childIDs`
5. `needsTutorial()` now returns `false` (has children!)
6. AuthGate rebuilds and shows `HomePage`

---

## 📱 User Experience

### **Complete New User Journey:**

1. **Register/Sign In** → Email/password or Google
2. **Email Verification** → Click link in email ✉️
3. **Phone Verification** → Enter phone + SMS code 📱
4. **Privacy Policy** → Read and accept 📜
5. **Research Survey** → Complete survey 📊
6. **Welcome Screen** → Learn about WordBuds 👋
7. **Add First Child** → Create child profile 👶
8. **Home Page** → Start using the app! 🎉

### **Returning User (Has Children):**

1. **Sign In** → Email/password or Google
2. **Home Page** → Skip tutorial (already has children) ✅

### **Existing User (No Children Yet):**

1. **Sign In** → Email/password or Google
2. **Welcome Screen** → (if they haven't added a child) 👋
3. **Add First Child** → Create first child 👶
4. **Home Page** → Start using the app! 🎉

---

## 🛠️ How to Modify

### **Add a New Tutorial Step**

1. **Add to enum** in `tutorial_flow_manager.dart`:
   ```dart
   enum TutorialStep {
     welcome,
     addFirstChild,
     appTour,  // NEW STEP
     completed;
   }
   ```

2. **Update logic** in `getCurrentStep()`:
   ```dart
   // After addFirstChild check
   if (!userProfile.hasSeenAppTour) {
     return TutorialStep.appTour;
   }
   ```

3. **Create page** `lib/pages/tutorial/app_tour_page.dart`

4. **Add to AuthGate**:
   ```dart
   case TutorialStep.appTour:
     return const AppTourPage();
   ```

### **Change Tutorial Requirements**

Currently, tutorial is based on `childIDs.isEmpty`. To track differently:

**Option 1: Add field to UserProfile**
```dart
class UserProfile {
  final bool tutorialCompleted;
  // ...
}
```

**Option 2: Use existing field**
```dart
// Tutorial complete if user has completed survey AND has children
return userProfile.surveyCompleted && userProfile.childIDs.isNotEmpty;
```

### **Skip Tutorial (Testing)**

Temporarily disable in `tutorial_flow_manager.dart`:

```dart
static bool needsTutorial(UserProfile? userProfile) {
  return false;  // Always skip
}
```

---

## 🎨 Design Highlights

### **Welcome Page**
- **Large mascot** at top (WordBuds logo)
- **Bold headline** "Welcome to WordBuds!"
- **Feature list** with icons
- **Prominent CTA** "Get Started" button
- **Clean, modern** Material Design 3

### **Add First Child Page**
- **Friendly instructions** "Let's get started! 🎈"
- **Clear form fields** with icons
- **Date picker** for birthday
- **Language chips** (multi-select)
- **Helper text** "You can add more children later"
- **Success feedback** when child is added

---

## 🔍 Testing

### **Test Complete Flow**

1. Create new account: `test+new@gmail.com`
2. Complete onboarding (email, phone, privacy, survey)
3. Should see **Welcome Screen**
4. Click "Get Started"
5. Should see **Add First Child**
6. Fill in child details
7. Click "Add Child & Continue"
8. Should see **Home Page**

### **Test Returning User**

1. Sign in with existing account that has children
2. Should skip tutorial and go directly to **Home Page**

### **Test Edge Cases**

- [ ] User with no children sees tutorial
- [ ] User with children skips tutorial
- [ ] Researcher/admin skips tutorial
- [ ] Tutorial persists across app restarts
- [ ] Can't skip tutorial (no back button)

---

## 📝 Future Enhancements

### **Short Term**
- [ ] Add app tour after first child (feature highlights)
- [ ] Add progress indicator during tutorial
- [ ] Track tutorial analytics (completion rate, drop-off)

### **Medium Term**
- [ ] Interactive tutorial with tooltips
- [ ] Video introduction to features
- [ ] Skip option for advanced users
- [ ] Personalized tutorial based on language

### **Long Term**
- [ ] Adaptive tutorial (learns user behavior)
- [ ] In-app help system triggered from tutorial
- [ ] Gamification (complete tutorial = unlock features)
- [ ] Multi-language tutorial support

---

## 📚 Key Files

```
lib/
├── auth/
│   └── tutorial_flow_manager.dart          # Tutorial logic
│
├── pages/
│   ├── new_auth_gate.dart                  # Orchestrates both flows
│   ├── tutorial/
│   │   ├── welcome_page.dart               # Step 1: Welcome
│   │   └── add_first_child_page.dart       # Step 2: Add child
│   └── onboarding/
│       ├── email_verification_page.dart    # Onboarding step 1
│       ├── phone_verification_page.dart    # Onboarding step 2
│       ├── privacy_policy_page.dart        # Onboarding step 3
│       └── survey_page.dart                # Onboarding step 4
│
└── util/
    └── child_utils.dart                    # Child creation logic
```

---

## 🐛 Troubleshooting

### **Tutorial doesn't show**
**Check:**
- User is a parent (not researcher/admin)
- User has no children in UserProfile
- Onboarding is complete

### **Welcome screen loops**
**Check:**
- `_welcomeCompleted` state is being set
- `setState()` is being called in callback

### **Child not being added**
**Check:**
- Firestore rules allow child creation
- User has completed survey (required for child creation)
- Console logs for errors

### **Tutorial shows for existing users**
**Expected behavior:** Users with existing children should skip tutorial
**If not:** Check `UserProfile.childIDs` is populated correctly

---

## 📊 Console Output

**Tutorial flow logs:**
```
NewAuthGate: Needs tutorial: true, welcomeCompleted: false
NewAuthGate: Tutorial step: Welcome
TutorialFlow: Step=Welcome, Progress=0%

[User clicks Get Started]

NewAuthGate: Needs tutorial: true, welcomeCompleted: true
NewAuthGate: Tutorial step: Welcome
[Shows AddFirstChildPage]

[User adds child]

✅ First child added successfully!
NewAuthGate: Needs tutorial: false
[Shows HomePage]
```

---

## ✅ Complete!

The tutorial flow is now ready to use. New parent users will get a guided introduction to the app, while returning users proceed directly to the app.

**Next Steps:**
- Test the complete flow end-to-end
- Gather user feedback on tutorial clarity
- Consider adding more tutorial steps as features grow

---

**Happy onboarding! 🎉**


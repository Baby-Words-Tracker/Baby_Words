
# Family Sharing: Dependencies and Implementation Plan

## 1. Feature Overview

The family sharing feature will allow multiple authorized users (ex. mother and father) to access the same child's account and shared data. Authorized users should be able to view and modify the child's data, including adding words and other information.

The purpose of this investigation was to determine what dependencies, services, data models, authorization mechanisms, and application changes are required to support family sharing within the existing application architecture.

The investigation found that the current codebase already contains most, and potentially all, of the functionality required for family sharing. The existing architecture already supports multiple parents associated with the same child, invitation and acceptance workflows, and shared access to child data. Therefore, the current implementation approach should primarily reuse and verify the existing functionality.

---

## 2. Current System Architecture

The project uses Firebase services for authentication, database access, and media storage, with application-specific services providing an abstraction between the Flutter application and these backend services.

The exact relationships between authentication, user profiles, child records, and Firestore authorization will be investigated before determining the implementation requirements for family sharing.

### Application Services

The existing application services relevant to family sharing that I identified are:

* `AuthenticationService` — `lib/auth/authentication_service.dart`
* `UserProfileModelService` — `lib/auth/user_profile_model_service.dart`
* `UserProfileService` — `lib/data/services/user_profile_service.dart`
* `OnboardingFlowManager` — `lib/auth/onboarding_flow_manager.dart`
* `CurrentChildrenService` — `lib/util/current_children_service.dart`
* `ChildDataService` — `lib/data/services/child_data_service.dart`
* `WordTrackerDataService` — `lib/data/services/word_tracker_data_service.dart`
* `PhraseTrackerDataService` — `lib/data/services/phrase_tracker_data_service.dart`
* `FirestoreRepository` — `lib/data/repositories/firestore_repository.dart`
* `MediaStorageService` — `lib/video/media_storage_service.dart`

### Firebase Services

The application uses:

* Firebase Authentication
* Cloud Firestore
* Firebase Cloud Functions
* Firebase Storage
* Firebase Cloud Messaging

For family sharing specifically, Firebase Authentication, Cloud Firestore, and Cloud Functions are the most relevant dependencies.

The repository contains Firestore security rules at: `firebase-project/firestore.rules`

The Cloud Functions implementation is located under: `firebase-project/functions/index.js`

---

## 3. Investigation Findings

### Authentication and User Profiles

The current application uses Firebase Authentication through `AuthenticationService`. Firebase UIDs identify users throughout the data model, while email addresses are used by the existing sharing workflow to identify another parent.

The current application uses the newer `UserProfile` model rather than the older `Parent` model. The relevant fields are:

* `childIDs` — children the parent currently has access to
* `pendingChildIDs` — children for which the parent has a pending sharing invitation
* `role` and `status` — used for authorization

`UserProfileModelService` maintains the authenticated user's profile and listens for profile changes in real time.

### User/Child Relationship

The existing data model already supports multiple parents.

```text
UserProfile A
    childIDs: [Child1]

UserProfile B
    childIDs: [Child1]

Child1
    parentIDs: [UserA, UserB]
```

`CurrentChildrenService` obtains the current user's `childIDs` and retrieves those children through `ChildDataService`. Therefore, no separate family-sharing child-management system is needed.

### Existing Sharing Workflow

Family sharing is already implemented through the following components:

* `child_utils.dart` provides the UI for sharing a child with another parent's email
* `addChildToOtherParent` creates the pending share
* `UserProfile.pendingChildIDs` stores the invitation
* `HomePage` detects pending shares and displays the acceptance dialog
* `acceptChildShare` removes the pending ID, adds the child to `childIDs`, and adds the recipient UID to the child's `parentIDs`
* `declineChildShare` removes the pending invitation without granting access

The existing flow is:

```text
Parent A
    ↓
Share child using Parent B's email
    ↓
addChildToOtherParent
    ↓
Parent B.pendingChildIDs
    ↓
Accept invitation
    ↓
Parent B.childIDs + Child.parentIDs
    ↓
Parent B can access shared child
```

### Shared Child Data

Child-specific data is stored under the shared `Child` document rather than under an individual parent.

`WordTrackerDataService` uses:

```text
Child/{childId}/WordTracker/{wordId}
```

`PhraseTrackerDataService` uses:

```text
Child/{childId}/PhraseTracker/{phraseId}
```

Because the data belongs to the child, authorized parents can work with the same underlying WordTracker and PhraseTracker records.

Other child-related pages, including `HomePage`, `DisplayMediaPage`, `DisplayVideoPage`, and `LogPage`, also operate on child-specific data.

### Authorization and Security

`firebase-project/firestore.rules` already contains authorization logic for the parent/child relationship.

For normal child access, the rules use both the child's `parentIDs` and the user's `childIDs`. Pending users can temporarily read a pending child so the invitation dialog can display the child's information.

WordTracker and PhraseTracker access is authorized using the child's `parentIDs`.

Therefore, once a sharing invitation is accepted and the second parent's UID is added to `Child.parentIDs`, the existing security model supports access to the shared data.

---

## 4. Existing vs. Legacy Architecture

The repository contains both a newer `UserProfile` architecture and an older `Parent` architecture.

### Current Architecture

Family sharing uses:

```text
UserProfile
    ↓
childIDs / pendingChildIDs

Child
    ↓
parentIDs

Cloud Functions
    ↓
addChildToOtherParent
acceptChildShare
declineChildShare
```

This is the architecture that should be used for new family-sharing work.

### Legacy Architecture

The repository also contains:

* `Parent`
* `ParentDataService`
* the older `Parent` Firestore collection

`ParentDataService` contains older methods such as `addChildToParent` and `removeChildFromParent`.

However, current code explicitly directs developers toward `UserProfile` and `UserProfileService` instead. Some existing code retains a fallback to `ParentDataService` only if the newer operation fails. This appears to be compatibility code from the transition between architectures, not the intended design for new functionality.

---

## 5. Dependencies

### Existing Dependencies

The existing architecture provides all major dependencies required for Family Sharing:

* **Firebase Authentication** — identifies users and provides UIDs/email information
* **Cloud Firestore** — stores users, children, parent relationships, pending shares, and child data
* **Firebase Cloud Functions** — handles `addChildToOtherParent`, `acceptChildShare`, and `declineChildShare`
* **Existing Flutter services** — provide authentication, user profile, child, and child-data management
* **Firestore Security Rules** — enforce access based on the existing parent/child relationships

---

## 6. Overall Conclusion

Family sharing is already substantially implemented.

The existing architecture supports multiple parents, invitations, acceptance and declining, shared child records, shared WordTracker and PhraseTracker data, and Firestore authorization.

The investigation therefore does **not** indicate that we need to introduce a new dependency, family-sharing data model, or separate backend service.

The next step is to test the existing implementation end-to-end with multiple parent accounts. If testing succeeds, this dependency investigation can be considered complete. Any remaining work would be testing, bug fixing, or UI refinement rather than a new foundational implementation.

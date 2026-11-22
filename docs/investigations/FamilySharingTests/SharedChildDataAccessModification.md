# Subissue 3 Shared Child Data Access and Modification

## Objective

Verify that a parent who accepts a family-sharing invitation can access the shared child's information and make changes that are reflected across both parent accounts.

## Test Environment

Testing was performed using the Flutter Android emulator and the Firebase Emulator Suite, including Authentication, Firestore, and Cloud Functions.

## Testing Performed

1. Parent A shared a child with Parent B, who successfully accepted the invitation.
2. Parent B accessed the shared child through their account and viewed the child's existing information.
3. Parent B added and modified information in the shared child's word-tracking records.
4. Parent A accessed the same child and confirmed that the changes made by Parent B were reflected in their account.
5. Verified that both parents could access and contribute to the same shared child data.

## Results

**PASS** — Shared child data access and modification functioned as expected. Both parents were able to view and update the child's information, with changes reflected across their accounts.
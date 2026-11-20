# Subissue 2 Accepting and Declining Family Shares

## Objective

Verify that a parent receiving a family-sharing invitation can successfully accept or decline access to a shared child.

## Test Environment

Testing was performed using the Flutter Android emulator and the Firebase Emulator Suite, including Authentication, Firestore, and Cloud Functions.

## Testing Performed

1. Parent A sent a child-sharing invitation to Parent B.
2. Parent B received the invitation and selected **Accept**.
3. Verified that Parent B gained access to the shared child and that the associated Firebase records were updated.
4. A separate invitation was sent to test the **Decline** option.
5. Parent B declined the invitation, and it was confirmed that no access to the child was granted.

## Results

**PASS** — Both acceptance and decline workflows functioned as expected. Accepting an invitation successfully granted access to the shared child, while declining removed the pending invitation without granting access.

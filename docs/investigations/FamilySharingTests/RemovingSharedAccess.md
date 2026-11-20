# Subissue 5 Removing / Ending Shared Access

## Objective

Verify that shared access to a child can be successfully removed and that a parent whose access has been revoked can no longer view or modify the child's information.

## Test Environment

Testing was performed using the Flutter Android emulator and the Firebase Emulator Suite, including Authentication, Firestore, and Cloud Functions.

## Testing Performed

1. Parent A shared a child with Parent B, who accepted the invitation.
2. Confirmed that Parent B could access the shared child's information.
3. Removed Parent B's access to the shared child.
4. Verified that the shared child was no longer accessible from Parent B's account.
5. Confirmed that Parent A retained access to the child's information after removing Parent B.

## Results

**PASS** — Shared access was successfully removed. Parent B could no longer access the child's information, while Parent A retained access to the child and its existing records.
# Subissue 4 Unauthorized Access and Security

## Objective

Verify that only authorized parents can access and modify a child's information, and that users who have not been granted access are restricted from viewing or changing shared child data.

## Test Environment

Testing was performed using the Flutter Android emulator and the Firebase Emulator Suite, including Authentication, Firestore, and Cloud Functions.

## Testing Performed

1. Created or used a separate parent account that had not been granted access to the shared child.
2. Tested whether the unauthorized account could view or access the child's information.
3. Attempted to access or modify the child's records without an accepted family-sharing invitation.
4. Confirmed that the unauthorized account could not access or modify the child's data.
5. Verified that parents who had accepted a sharing invitation retained their authorized access.

## Results

**PASS** — Unauthorized access restrictions functioned as expected. Users without permission were prevented from accessing or modifying the shared child's information, while authorized parents retained access.
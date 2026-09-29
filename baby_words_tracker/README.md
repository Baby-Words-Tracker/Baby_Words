# baby_words_tracker

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Developer setup

### Email verification during local development

The onboarding flow normally requires Firebase email verification before a user
can continue. For local debug runs only, you can bypass that step with a Dart
define:

```sh
flutter run --dart-define=BYPASS_EMAIL_VERIFICATION=true
```

This flag is intentionally gated behind Flutter debug mode, so it is ignored in
profile/release builds.

The email verification page also rate-limits automatic verification email sends.
When the page first opens, it sends a verification email only if one has not
already been sent automatically in the last 2 minutes. Manual taps on **Resend
Email** still send another verification email.

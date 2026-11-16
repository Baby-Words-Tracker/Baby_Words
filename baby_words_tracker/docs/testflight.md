# Redeploy WordBuds to TestFlight

Run commands from the `baby_words_tracker` directory. You need access to the
Apple Developer team and WordBuds in App Store Connect.

## 1. Check signing

```sh
open ios/Runner.xcworkspace
```

In Xcode, select **Runner → TARGETS → Runner → Signing & Capabilities**:

- Enable **Automatically manage signing**.
- Select the WordBuds Apple Developer team.
- Confirm the bundle identifier is **edu.ua.wordbuds**.
- Resolve any signing errors before building.

## 2. Build

Use a build number higher than the last uploaded build. For example, if the
latest build is `1.0.0 (2)`, build `3`:

```sh
flutter pub get
flutter build ipa --release --build-name=1.0.0 --build-number=3
```

The `.ipa` is generated in **build/ios/ipa/**. Increment the build number for
every new upload; keep `1.0.0` unless intentionally changing the app version.

## 3. Upload

1. Open Apple's **Transporter** Mac app and sign in with your developer account.
2. Drag the new `.ipa` from **build/ios/ipa/** into Transporter.
3. Click **Deliver** and wait for the upload to finish.
4. Open **App Store Connect → My Apps → WordBuds → TestFlight**.
5. Wait for the build to finish processing. Resolve any **Missing Compliance**
   or other warnings using the build's actual encryption/distribution details.

## 4. Add testers

### Internal testers (development team)

1. In App Store Connect, add team members under **Users and Access** if needed,
   giving them an eligible role and access to WordBuds.
2. Go to **WordBuds → TestFlight → Internal Testing → Development Team**.
3. Add the new build if it isn't already included by automatic distribution.
4. Under **Testers**, add the team members you want to invite.
5. Testers accept their invitation and install/update WordBuds using the
   **TestFlight** app on their iPhone.

If the group is disabled in **Add Group to Build**, check whether the build is
already listed in that group's **Builds** tab.

### External testers (people outside the team)

1. Create/select a group under **TestFlight → External Testing**.
2. Add the build, complete the required testing information, and submit for
   **TestFlight App Review** when prompted.
3. Once approved, invite testers by email or enable a public invitation link.

Internal testing does not require TestFlight App Review. TestFlight builds
expire after 90 days.

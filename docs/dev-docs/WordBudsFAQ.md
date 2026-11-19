# WordBuds (Baby Words Tracker) — Repository Handoff & FAQ

This document serves as the complete technical repository handoff, architecture guide, frequently asked questions (FAQ), and transfer checklist for **WordBuds** (Baby Words Tracker), developed for The University of Alabama's Literacy Education & Cognitive Science Lab (LECS) as part of CS495 (Capstone Course).

---

## 1. Project Overview & Architecture

* **Purpose:** WordBuds is a cross-platform mobile app and researcher dashboard built to track child speech development for LECS. Parents log learned words, complete an onboarding demographic survey, upload speech videos, and share child profiles, while LECS researchers access study data.
* **Repositories & Live Endpoints:**
  * **Mobile App Repository:** `Baby-Words-Tracker/Baby_Words`
  * **Dashboard Repository:** `Baby-Words-Tracker/Baby-Words-Researcher-Dashboard`
* **Tech Stack:**
  * **Mobile:** Flutter / Dart
  * **Backend:** Firebase (Authentication, Cloud Firestore, Cloud Storage, Cloud Functions)
  * **Dashboard:** Angular `v21.1.2` / TypeScript, Vitest & Playwright, Docker / Nginx

---

## 2. Workflows, Testing & Deployment

* **Testing:** Refer to `dev-docs/Testing Plan and Cases.pdf` for mobile test plans and cases. Dashboard unit and end-to-end tests are configured with Vitest and Playwright.
* **Build & Deployment:** Refer to `dev-docs/deployment.md`  for detailed deployment steps:
  * **Mobile App:** Build iOS and Android release packages following the instructions in `dev-docs/deployment.md`.
  * **Firebase Backend:** Authenticate via `firebase login`, select the project with `firebase use baby-word-tracker`, install dependencies inside `firebase-project/functions` (`npm install`), and deploy functions and security rules.
  * **Dashboard:** Build with `ng build` (outputs to `dist/` served via Docker/Nginx); CI/CD workflows are configured under `.github/workflows/`.

---

## 3. Frequently Asked Questions (FAQ)

### General, End-User & Development

* **Where can I find existing user and developer documentation?**
  Detailed guides are stored inside `Baby_Words/dev-docs/`:
  * `Development Guide.pdf` (environment setup and architecture)
  * `deployment.md` (build and release workflows)
  * `Testing Plan and Cases.pdf` (QA and test cases)
  * `User Guide.pdf` (end-user walkthrough)
  * `WordBudsFAQ.pdf` (Developer FAQ)

* **Why are there two separate GitHub repositories?**
  The Flutter mobile app (`Baby_Words`) and Angular dashboard (`Baby-Words-Researcher-Dashboard`) use distinct tech stacks and independent CI/CD pipelines.

* **Why is the build failing right after I clone the repository?**
  Ensure all local initialization steps are complete before building:
  1. Run `flutter pub get` inside `Baby_Words/baby-words-tracker`.
  2. Place the required Firebase configuration files (`google-services.json`, `GoogleService-Info.plist`, and `firebase_options.dart`) in their expected directories.
  3. Follow the complete environment setup checklist in `dev-docs/Development Guide.pdf`.

* **Why are my Cloud Functions not deploying on the first try?**
  Deployment fails with `"Couldn’t find firebase-functions package in your source code"` because the `functions` folder maintains its own `node_modules`. Run `npm install` inside `firebase-project/functions` before deploying.

* **What must I run before deploying Firebase backend changes?**
  Install the Firebase CLI globally (`npm install -g firebase-tools`), run `firebase login` to authenticate via Google OAuth, and verify the active project with `firebase use baby-word-tracker`.

* **How do I get Flutter to open on my emulator instead of Chrome or desktop?**
  Boot the Android emulator beforehand (`flutter emulators --launch <id>`), pass its ID directly (`flutter run -d <device-id>`), or select the booted emulator from the device dropdown in VS Code or Android Studio.

---

### API Keys & Secrets

* **What external services and authentication flows does WordBuds depend on?**
  WordBuds relies on Firebase Authentication, Cloud Firestore Cloud Storage and Cloud Functions Developers authenticate via Google OAuth indirectly using `firebase login`.

* **What configuration files are required across both repositories?**
  * **Mobile (`Baby_Words`):** `google-services.json` (Android), `GoogleService-Info.plist` (iOS), and `firebase_options.dart`.
  * **Dashboard (`Baby-Words-Researcher-Dashboard`):** Firebase Web SDK configuration (`apiKey`, `projectId`, `authDomain`, etc.) inside `src/environments/`.

* **Are Firebase client keys secret, and what must stay out of Git?**
  Firebase client configs act as project identifiers rather than admin credentials. However, keeping config files out of public repos is still recommended. **Never commit** Firebase Admin service account JSONs, `.env` files, Android release keystores (`.jks`), or Apple signing certificates to Git.

* **How should keys and CI/CD credentials be maintained or rotated?**
  Restrict browser API keys by HTTP referrers (`wordbuds.info`) and mobile keys by package/bundle ID in Google Cloud Console. If a service account or secret is ever exposed, revoke and rotate it immediately in Firebase/GCP IAM, and store CI/CD secrets in GitHub Actions Secrets.

---

### Hosting Costs

* **What infrastructure incurs recurring or one-time costs?**
  * **Firebase (`baby-word-tracker`):** Free Spark tier.
  * **App Stores & Documentation Hosting:** Apple Developer Program ($99/year), Google Play Console ($25 one-time).

---

### Third-Party Service Limits

* **What happens if Firebase's free Spark tier limits are exceeded?**
  The Spark plan caps daily Firestore reads (50,000), writes (20,000), and deletes (20,000), plus Cloud Storage (5 GB stored, 1 GB/day download bandwidth). When exceeded, **the app fails silently rather than showing a clear error**, and quotas do not reset until midnight Pacific Time.

* **What are the limits and requirements for Cloud Functions and Authentication?**
  Firebase Auth supports up to 50,000 monthly active users (MAUs) for free. Cloud Functions require the Blaze plan (which includes 2 million free invocations/month) and enforce a 60-second default execution timeout (540 seconds max).

---

### Data Persistence & Backup

* **Where does study data live?**
  User accounts, demographic surveys, child profiles, sharing relationships, and word logs are stored in Cloud Firestore.

* **How are database and video backups handled?**
  Firebase does not enable automated backups by default. LECS administrators should run regular CSV/JSON exports via the researcher dashboard.

* **How do researchers export data?**
  Researchers can export structured CSV/JSON datasets from the dashboard for external analysis.

---

### Known Limitations

* **Why does the researcher portal sometimes load a blank page?**
  Refreshing the browser tab typically resolves the issue and loads the portal normally.

* **Why is there an occasional multi-second delay when classifying words or sharing a child?**
  Cloud Functions experience cold-start latency when a function has not been invoked recently, requiring Firebase to spin up a new container. Subsequent calls within the same active session run much faster.

* **What security, upload, and environment limitations exist?**
  Both repositories share the same live `baby-word-tracker` Firebase project without a separate staging instance, so Firestore schema changes in one repository can break the other.

---

## 4. Account Ownership & Handoff Checklist

* **Who owns the WordBuds intellectual property, code, and research data?**
  All repositories, domains, cloud resources, and collected participant data belong to The University of Alabama's LECS Lab.

* **How is ownership transferred across platforms?**
  * **GitHub (`Baby-Words-Tracker`):** Verify LECS faculty/advisors are set as **Organization Owners**.
  * **Firebase & Google Cloud (`baby-word-tracker`):** Verify LECS Google accounts are set as **Project Owners** in IAM.
  * **App Stores:** Verify LECS faculty have **Admin / Account Holder** access in Google Play Console and App Store Connect / TestFlight.

# Aarogya Sahayak (Aarogya Sahayak — Health Monitoring + ASHA Connect)

A friendly, offline-first Flutter app that connects community members (patients) with ASHA workers to track vitals, share reports (with OCR), receive alerts, schedule visits, and access multilingual health education. This README gives everything a developer needs to understand, run, and contribute to the project.

---

# Table of Contents

* Project Overview
* Key Features
* Architecture & Tech Stack
* Folder Structure (important)
* Getting Started (prereqs + setup)
* Firebase Setup (quick)
* Local Development (commands)
* Data Flow & Offline Sync
* State Management & Providers
* Localization (l10n)
* Testing & Debugging
* CI / CD Recommendations
* Security & Privacy Notes
* Roadmap
* Contributing
* Troubleshooting & FAQ
* License & Credits
* Contact

---

# Project Overview

**Aarogya Sahayak** is a cross-platform Flutter application built for low-connectivity environments. It enables users to:

* record daily vitals (blood pressure, blood sugar, weight),
* upload medical reports and extract data using OCR,
* connect to local ASHA workers for monitoring and help,
* receive alerts when vitals are abnormal,
* view multilingual health content,
* set reminders and schedule home visits,
* work offline and sync when connection is available.

The app is designed for scalability and privacy-first operation with Firebase as the cloud backend and Hive/SQLite for local caching.

---

# Key Features

* Offline-first data storage + background sync
* Multi-language (English / Hindi / Marathi) UI
* Phone OTP and Email authentication (Firebase Auth)
* Vitals logging with validation and warning logic
* Vitals trends and export (CSV placeholder)
* ASHA dashboard to monitor patients and alerts
* Chat between patient and ASHA (Firestore-backed)
* Report upload + OCR parsing + manual verification
* Notifications and reminders (FCM + local notifications)
* Simple role separation: Patient (user) & ASHA (health worker)

---

# Architecture & Tech Stack

* Frontend: Flutter (Dart)
* State management: Provider (pattern used in `providers/`)
* Cloud Backend: Firebase (Auth, Cloud Firestore, Storage, Functions, FCM)
* Local storage: Hive (or SQLite) for offline-first capability
* OCR: on-device or cloud OCR service (abstracted by `ocr_service.dart`)
* Charts: `fl_chart` or similar for vitals trends
* CI/CD: GitHub Actions (recommended) for building & tests
* Localization: Flutter `l10n` (ARB files)

---

# Folder Structure (lib/)

This project follows a modular layout. Create files as described in the spec. Important files/folders:

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── constants.dart                 # App constants, colors, strings
│   ├── theme.dart                     # Material theme config
│   ├── routes.dart                    # Navigation route definitions
│   ├── utils/                         # validators, date & health helpers
│   └── services/                      # firebase, local storage, ocr, sync, notifications
├── models/                            # data models (User, Vitals, ASHA, Chat, Report, Reminder)
├── screens/
│   ├── common/                        # splash, language selection, auth
│   ├── user/                          # dashboard, vitals input, trends, feed, profile
│   └── asha/                          # asha dashboard, patients, patient details, asha chat
├── widgets/                           # reusable UI components grouped by common/user/asha
├── providers/                         # app state providers: auth_provider, user_provider, vitals_provider...
├── l10n/                              # app_en.arb, app_hi.arb, app_mr.arb
└── data/
    ├── local/                         # hive_service.dart etc.
    └── remote/                        # firestore_service.dart
```

> Each `.dart` file should include a small doc comment at the top describing its purpose and a TODO note showing where to wire providers/services.

---

# Getting Started (Prerequisites)

1. Install Flutter (stable channel). See Flutter docs for platform-specific install.
2. Install Dart SDK (bundled with Flutter).
3. Install Android Studio / Xcode or configure desired editors.
4. Ensure `flutter` is in your PATH.
5. Set up a Firebase project (see Firebase Setup below).
6. Add Android/iOS apps in Firebase; download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
7. Add Firebase configuration files to appropriate platform folders.
8. (Optional) Configure in-app OCR API keys or use on-device ML solution.

---

# Firebase Setup (quick)

1. Create a Firebase project.
2. Enable:

    * Authentication (Phone and Email/Password)
    * Firestore (set rules for roles)
    * Storage (for report uploads & profile photos)
    * Cloud Functions (optional — e.g., heavy OCR, scheduled jobs)
    * FCM (for push notifications)
3. Download and place config files:

    * Android: `android/app/google-services.json`
    * iOS: `ios/Runner/GoogleService-Info.plist`
4. Add server-side environment variables (if using Cloud Functions) via Firebase Console or `firebase functions:config:set`.
5. Add Firestore indexes if you plan to query frequently on composite fields (patients by PIN + alert timestamp).

---

# Environment variables & Example (.env)

Create a `.env` or use `--dart-define` in production:

```
FIREBASE_API_KEY=xxxxx
FIREBASE_APP_ID=1:xxxx:android:xxxx
OCR_API_KEY=xxxxx            # if external OCR used
SENTRY_DSN=                  # optional crash reporting
```

> Keep secrets out of VCS. Use CI secrets or firebase environment for functions.

---

# Local Development (useful commands)

* Install packages:

  ```
  flutter pub get
  ```
* Run on device:

  ```
  flutter run
  ```
* Run on emulator:

  ```
  flutter emulators --launch <emulator_id>
  flutter run
  ```
* Build APK (release):

  ```
  flutter build apk --release
  ```
* Build iOS (release):

  ```
  flutter build ios --release
  ```
* Lint & analyze:

  ```
  flutter analyze
  dart format .
  ```
* Run tests:

  ```
  flutter test
  ```

---

# Data Flow & Offline Sync

* **Local writes**: When a user saves vitals or uploads a report offline, data is saved to Hive (or SQLite) and queued.
* **SyncService** watches connectivity (ConnectivityProvider) and syncs queued writes with Firestore when online.
* **Conflict resolution**: Latest-timestamp-wins; flag conflicting records for manual review (TODO: implement).
* **Push alerts**: Cloud Functions can trigger FCM when vitals exceed thresholds.

---

# State Management & Providers

The app uses Provider to expose app-wide state. Example providers:

* `AuthProvider` — login/logout, currentUser
* `UserProvider` — profile, dashboard data
* `VitalsProvider` — CRUD for vitals, trends, statistics
* `AshaProvider` — patient lists, connection requests
* `ChatProvider` — messages streaming and queueing
* `ConnectivityProvider` — online/offline status
* `LanguageProvider` — locale management

Each provider should have methods for sync with `SyncService` and minimal business logic; the heavy lifting (cloud functions, expensive computation) should be server-side.

---

# Localization (l10n)

* `l10n/app_en.arb`, `app_hi.arb`, `app_mr.arb` contain strings.
* Use context-based translation helpers: `context.l10n.someKey`.
* Steps to generate:

  ```
  flutter gen-l10n
  ```
* Keep all user-facing strings in ARB files and avoid inline English.

---

# Testing & Debugging

* Unit tests: models, utils (validators, date\_utils, health\_utils).
* Widget tests: key UI screens (splash, auth, vitals input).
* Integration tests: simulate login + vitals entry + sync.
* For Firestore interactions, mock services or use Firebase Emulator Suite:

  ```
  firebase emulators:start --only firestore,auth,functions
  ```

---

# CI / CD Recommendations

* Use GitHub Actions:

    * `flutter analyze` + `flutter test`
    * Build artifacts for Android & iOS
    * Upload artifacts to release channel or TestFlight / Play Console
* Store secrets in repository secrets (OCR keys, Firebase service account for server tasks).
* Run `flutter format` and `dart analyze` before merging PRs.

---

# Security & Privacy Notes

* Personal health data is sensitive. Always:

    * Use Firebase security rules to restrict reads/writes by role.
    * Encrypt sensitive local storage (consider using flutter\_secure\_storage for tokens).
    * Do not log PII in logs.
    * Obtain consent for OCR scanning and explicitly show privacy policy.
    * Consider regional legal/regulatory requirements (e.g., India-specific data protection) before deploying at scale.

---

# Roadmap (suggested)

Short-term:

* Implement full screen templates and providers.
* Implement basic offline sync with Hive.
* Basic OCR integration + manual verification UI.
* ASHA connection flow & chat (Firestore).

Mid-term:

* Analytics & user insights; trend notifications.
* Export CSV, share chart images.
* Improve OCR accuracy & support multi-language OCR.
* Smart alerts + triage automation using Cloud Functions.

Long-term:

* Telemedicine integration (video/voice).
* Integration with government health schemes/APIs.
* AI-driven health tips and anomaly detection.

---

# Contributing

We 💚 contributions! To contribute:

1. Fork the repo.
2. Create a feature branch: `git checkout -b feat/your-feature`.
3. Run `flutter pub get` and implement changes.
4. Add tests for your feature.
5. Open a PR with description & screenshots.
6. Follow code style: `dart format .` and ensure `flutter analyze` passes.

Please open issues for bugs and feature requests. Label them clearly: `bug`, `enhancement`, `question`.

---

# Troubleshooting & FAQ

Q: App fails to start due to Firebase config?

* Ensure `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS) are placed correctly.
* Run `flutter pub get`, then `flutter clean` if needed.

Q: OCR returns wrong values?

* Validate parsed output before saving; allow user correction. Consider server-side OCR for better accuracy.

Q: Offline data not syncing?

* Check `ConnectivityProvider` status and ensure `SyncService` is listening. Use Firebase Emulator for debugging.

Q: Tests failing locally but passing in CI?

* Ensure emulator versions & local env match CI; clear caches with `flutter clean`.

---

# License & Credits

* License: MIT (or choose appropriate license). Add LICENSE file to repo.
* Credits: Based on the design spec in `SahayakApp.pdf`. Icons & images used must have proper attribution or be royalty-free.

---

# Contact

Project Maintainer: *Your Name / Team*
Email: [your.email@example.com](mailto:your.email@example.com)
GitHub: `https://github.com/your-org/aarogya-sahayak` (replace with repo)

---

# Final Notes (developer tips)

* Keep UI and business logic separated: widgets → UI, providers → state & minimal business logic, services → backend & platform-specific code.
* Add Crash reporting (Sentry / Firebase Crashlytics) early to catch issues on devices.
* Document data models (User, Vitals, Report) in a `docs/` folder for easier backend integration.
* Start with small MVP: auth → vitals input → basic sync → ASHA connect → chat. Iterate.

---

Want me to:

* generate the **README.md** file as a downloadable file, or
* scaffold `lib/screens/` files with minimal Dart templates and TODOs next?
# Runtime-Terror_Internal-Round_58

# HabitDuel

HabitDuel is a competitive habit-tracking app where users turn personal goals into duels, streaks, ratings, trophies, and profile progress. The project is prepared as a demo-ready Flutter APK with Firebase integration and a local Dart/PostgreSQL backend for API flows and load testing.

## Product Highlights

- Habit duels: create 1v1 or group challenges, accept invites, check in, and track streaks.
- Motivation mechanics: XP, trophies, achievements, leaderboard, shop items, boosters, and avatars.
- Player profile: editable bio, favorite habit, avatar URL, stats, wins, losses, and badges.
- Demo economy: entry fees for duels, in-app currency fields, and test shop goods.
- Realtime layer: Firebase Auth and Cloud Firestore are used as the main app data layer, with REST fallback pieces still available for backend scenarios.
- APK branding: Android label is `HabitDuel`, app icon is generated from `assets/branding/app_icon.png`, and release APK files are named as `HabitDuel-v<version>+<build>-release.apk`.

## Tech Stack

- App: Flutter, Dart, Riverpod, Firebase Auth, Cloud Firestore, Firebase Messaging, local notifications.
- Backend: Dart Shelf API, PostgreSQL, Docker Compose.
- Testing: `dart analyze`, Flutter tests, k6 load tests for the backend API.

## Quick Demo Run

Start the backend:

```powershell
docker compose up -d --build db migrate server
```

Check that the API is alive:

```powershell
curl http://localhost:8080/healthz
```

Find your computer IP address on the same Wi-Fi network as the phone:

```powershell
ipconfig
```

Build a release APK for the phone:

```powershell
C:\flutter\bin\flutter.bat build apk --release --dart-define=API_BASE_URL=http://<YOUR_PC_IP>:8080
```

The APK appears in:

```text
build\app\outputs\flutter-apk\
```

The generated file name should look like:

```text
HabitDuel-v1.0.0+1-release.apk
```

## Phone Testing Without Rebuilding an APK

For fast checks over USB-C, connect the phone with USB debugging enabled and run:

```powershell
C:\flutter\bin\flutter.bat devices
C:\flutter\bin\flutter.bat run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://<YOUR_PC_IP>:8080
```

This installs a debug build and supports hot reload while the app is running. A final release APK still needs a rebuild.

## Quality Checks

Analyze Flutter code:

```powershell
C:\flutter\bin\dart.bat analyze lib
```

Run backend load tests:

```powershell
docker compose --profile load run --rm k6
```

More k6 details live in `load-tests/k6/README.md`.

## Demo Checklist

- Phone and computer are connected to the same network.
- `API_BASE_URL` points to the computer LAN IP, not `localhost`.
- Windows Firewall allows inbound connections to port `8080`.
- Backend containers are healthy before installing the APK.
- Firebase project contains the required Android app config.
- Release APK is for sideload/demo only unless proper release signing is configured.

## Firebase Demo Data

Demo Firestore JSON lives in `server/exports/firebase-demo`. To import it, put a Firebase service account JSON at the repo root as `service-account.json` or set `FIREBASE_SERVICE_ACCOUNT_PATH`, then run from `server`:

```powershell
$env:EXPORT_DIR='exports/firebase-demo'
$env:DEMO_CURRENT_USER_ID='<your Firebase Auth uid>'
$env:DEMO_CURRENT_USERNAME='Aliar'
dart run bin/import_firebase.dart
```

Use `IMPORT_DRY_RUN=true` first if you only want to verify the target project and row counts.

## Project Structure

```text
lib/                 Flutter app source
android/             Android project and APK build config
assets/branding/     App logo and launcher icon source
server/              Dart Shelf API
load-tests/k6/       Backend k6 scenarios
docs/design/         Product and UI design notes
docs/firebase/       Firebase setup and archived update notes
docs/ops/            Operations notes
docs/project/        Implementation summary
```

## Notes For Release

Current Android release builds use the debug signing config so the APK can be installed easily during development. Before publishing to Google Play, replace it with a real release keystore and keep the keystore credentials outside the repository.

Firebase APK self-updates were intentionally removed from the visible app flow for this version because Firebase Storage is unavailable on the current project plan. APK updates can still be distributed manually for the final demo.

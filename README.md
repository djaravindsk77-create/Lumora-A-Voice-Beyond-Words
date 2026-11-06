# Lumora – Voice & Safety Companion for Specially-Abled Children

> **“Every voice matters.”**

Lumora is a Flutter mobile application that helps specially-abled children
communicate through pictures, voice and sentences, learn through gentle
activities, follow visual routines, and call for help when they need it —
while parents/caregivers manage everything from a full dashboard.

The app ships in **Demo Mode**: it runs fully offline with fictional sample
data and requires no accounts, no Firebase project, and no API keys to try
every feature.

---

## 1. Requirements

| Tool | Version |
| --- | --- |
| Flutter SDK | 3.24 – 3.35 (stable), Dart ≥ 3.5 |
| Android Studio | Ladybug or newer |
| Flutter plugin | latest |
| Dart plugin | latest |
| Android SDK | API 34/35 |
| Java | 17 (bundled with Android Studio) |

---

## 2. Setup in Android Studio (exact steps)

1. **Install the Flutter SDK** – follow https://docs.flutter.dev/get-started/install
   and add `flutter/bin` to your `PATH`.
2. **Install Android Studio** – https://developer.android.com/studio
3. **Install the Flutter and Dart plugins** –
   *Android Studio → Settings → Plugins → Marketplace → search “Flutter” → Install*
   (this installs the Dart plugin automatically).
4. **Open this project**: *File → Open…* → select the `lumora` folder.
5. Verify the Flutter SDK path: *File → Settings → Languages & Frameworks → Flutter →
   SDK path*.
6. Run in the terminal (Android Studio → View → Tool Windows → Terminal):

```bash
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter run
```

7. Choose an Android emulator (Device Manager → create a Pixel AVD) or a real
   device with USB debugging, then press **Run ▶**.

### Build an APK

```bash
flutter build apk --debug
```

The APK is written to:

```
build/app/outputs/flutter-apk/app-debug.apk
```

For a release build: `flutter build apk --release`
(→ `build/app/outputs/flutter-apk/app-release.apk`).

---

## 3. Demo Mode (no Firebase needed)

The app **opens in Demo Mode by default**. It:

* seeds a fictional local database at first launch (child “Arun”, demo parent,
  teacher, therapist, 16 AAC categories, 70+ picture cards, phrases, routines,
  contacts, alerts, notes and 14 days of history), and
* stores everything offline on the device (Hive + SharedPreferences).

Demo accounts (sign in on the Login screen with **any password**):

| Email | Role |
| --- | --- |
| `parent@demo.lumora` | Parent |
| `teacher@demo.lumora` | Teacher |
| `therapist@demo.lumora` | Therapist |
| `caregiver@demo.lumora` | Caregiver |

Or tap **Try Demo Mode** to enter directly as child/parent.

---

## 4. Firebase setup (optional)

Lumora has a Firebase-ready architecture. Without configuration it stays in
Demo Mode; nothing crashes and no data leaves the device.

1. Create a project at https://console.firebase.google.com.
2. Add an **Android app** with package name `com.example.lumora`
   (change the id in `android/app/build.gradle.kts` if you rename it).
3. Download **`google-services.json`** and place it at:

   ```
   android/app/google-services.json
   ```

4. Enable in the Firebase console:
   * **Authentication → Email/Password**
   * **Cloud Firestore** (production mode)
   * **Firebase Storage**
   * **Cloud Messaging** (optional)
5. (iOS) add `ios/Runner/GoogleService-Info.plist` the same way.
6. Generate the Firebase options file:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Then open `lib/data/firebase/firebase_options_stub.dart` and follow its
   comment to return `DefaultFirebaseOptions.currentPlatform`.
7. Uncomment the two Firebase Gradle lines in `android/build.gradle.kts`
   (marked with `TODO(firebase)`), then run:

   ```bash
   flutter clean && flutter pub get
   ```

8. Launch with the remote mode:

   ```bash
   flutter run --dart-define=LUMORA_DATA_MODE=firebase
   ```

> The `google-services.json` file contains app identifiers, not secrets, but
> keep it out of public repos anyway (already ignored in `.gitignore`).

### Cloud Functions (optional)

`functions/` contains a TypeScript Cloud Functions structure. Deploy with:

```bash
cd functions
npm install
npm run deploy
```

### Environment configuration / API keys

Never hardcode keys. Provide them at build time:

```bash
flutter run \
  --dart-define=LUMORA_DATA_MODE=demo \
  --dart-define=LUMORA_AI_ENDPOINT=https://api.example.com/v1 \
  --dart-define=LUMORA_AI_API_KEY=your-key \
  --dart-define=LUMORA_ENABLE_AI=false
```

`.env.example` lists every supported key. Copy it to `.env` for documentation
(dart-define values are what the app actually reads).

---

## 5. Android permissions

Declared in `android/app/src/main/AndroidManifest.xml`:

| Permission | Why |
| --- | --- |
| `RECORD_AUDIO` | speech-to-text + caregiver audio (consent-driven) |
| `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM` | reminders & safety alerts |
| `READ_MEDIA_IMAGES` | photos for custom picture cards |
| `INTERNET` | optional cloud sync |
| `VIBRATE` | gentle haptic feedback |

Runtime requests happen only inside the relevant feature and the app keeps
working when a permission is denied (fallbacks: text input, icon cards,
in-app notification history).

---

## 6. Customisation

* **Change the app name**: `android/app/src/main/AndroidManifest.xml`
  (`android:label`), `ios/Runner/Info.plist` (`CFBundleDisplayName`), and
  `lib/core/config/app_config.dart` (`appName`).
* **Change the app icon**: use https://fluttercommunity.dev/ `flutter_launcher_icons`
  or replace the PNGs in `android/app/src/main/res/mipmap-*`.
* **Add a language**: add `l10n_xx.dart` in `lib/core/localization/`,
  register it in `AppLocalizations._mapFor` and `AppLocales.supported`,
  then add the locale to `ios/Runner/Info.plist` (CFBundleLocalizations) if
  building for iOS.
* **Adjust speech**: Settings on device, defaults in
  `lib/core/constants/app_constants.dart`.

---

## 7. Project structure

```
lib/
├── main.dart                 # bootstrap: env → Firebase → storage → TTS → run
├── app.dart                  # providers + MaterialApp.router + themes
├── core/
│   ├── config/               # AppConfig, EnvConfig (dart-define)
│   ├── constants/            # storage keys, boxes, asset paths
│   ├── localization/         # l10n_en.dart, l10n_ta.dart, AppLocalizations
│   ├── routing/              # GoRouter config + route hosts
│   ├── theme/                # colours, typography, Material 3 themes
│   ├── accessibility/        # announcer
│   └── utilities/            # feedback, formatters, icon catalog
├── models/                   # 22+ null-safe models with JSON round-trips
├── data/
│   ├── local/                # Hive-backed LocalDataSource (offline-first)
│   ├── demo/                 # fictional DemoData + seeder
│   └── firebase/             # FirebaseDataSource + options stub
├── repositories/             # LumoraRepository façade (UI never touches SDKs)
├── services/
│   ├── speech/               # TTS + speech-to-text (graceful fallbacks)
│   ├── audio/                # saved-audio playback
│   ├── notifications/        # local notifications, quiet hours, history
│   ├── permissions/          # consent-driven runtime permissions
│   ├── location/             # consent-based, always-visible sharing
│   ├── ai/                   # rule-based engine + optional AI hook
│   └── sync/                 # offline queue and status
├── providers/                # Provider state (settings, session, comm, ...)
├── widgets/                  # shared UI (cards, states, charts, strip)
└── features/                 # one folder per module, ~40 screens
```

---

## 8. Feature map

| Module | Route | Works offline |
| --- | --- | --- |
| Child Home | `/child-home` | ✅ |
| Voice communication (TTS + STT) | `/voice` | ✅ (STT when supported) |
| AAC board (16 categories) | `/aac` | ✅ |
| Sentence builder | `/sentence-builder` | ✅ |
| My Needs (14 quick cards) | `/needs` | ✅ |
| Feelings & comfort flow | `/emotions` | ✅ |
| Mood history & calendar | `/emotions/history` | ✅ |
| Confidence tracker + badges | `/tracker` | ✅ |
| Context modes (10) | `/modes` | ✅ |
| Learn & Play (18 activities) | `/learn` | ✅ |
| Social stories (10, EN/TA) | `/stories` | ✅ |
| Creative (draw/music/gallery) | `/creative` | ✅ |
| Visual routine planner | `/routines` | ✅ |
| Step-by-step guidance | `/routines/task/:id` | ✅ |
| Visual timer | `/timer` | ✅ |
| Reminders | `/reminders` | ✅ |
| Calm Space | `/calm` | ✅ |
| Safety + alerts | `/safety` | ✅ |
| Trusted contacts | `/trusted-contacts` | ✅ |
| Lost Child Mode | `/lost-mode` | ✅ |
| Parent dashboard | `/parent-dashboard` | ✅ |
| Child management | `/parent/child` | ✅ |
| Content management | `/parent/content` | ✅ |
| Home layout editor | `/parent/home-layout` | ✅ |
| Collaboration & invites | `/collaboration` | ✅ |
| Reports & export | `/reports` | ✅ |
| Settings / accessibility / privacy | `/settings` | ✅ |
| Notification centre | `/notifications` | ✅ |

---

## 9. Privacy & safety principles

* No medical, psychological or diagnostic claims anywhere in the app.
* Progress compares a child only with their own past activity.
* Tracking can be disabled and history deleted from Settings → Privacy.
* Location sharing is off by default, consent-based, always visible while
  active, and manually disableable.
* Safety alerts show honest statuses (sent / pending / failed /
  acknowledged) and never guarantee emergency delivery.
* No secrets are committed; configuration arrives via `--dart-define`.

---

## 10. Verification commands

```bash
flutter pub get      # fetch packages
flutter analyze      # static analysis
flutter test         # unit + widget tests (test/)
flutter build apk --debug
```



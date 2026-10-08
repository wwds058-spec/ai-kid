# AI Explorer — Setup

> **Toolchain:** Flutter **3.47.6** (Dart 3.13), Android Gradle Plugin 9.1, Gradle 9.3.1, Kotlin 2.4, JDK 17+. App targets and compiles against Android 16 (API 36), minSdk 24.
> Models are persisted to Hive as JSON strings (no Hive adapters / hive_generator).
> `android/` is committed (manifest permissions included); skip steps 1–3.

## 1. Create the Flutter project (run once)

```bash
flutter create --org com.yasin --project-name ai_explorer --platforms android .
```

## 2. Replace generated files

Copy everything from this package into the project root.
The generated `lib/main.dart` will be replaced by the one here.

## 3. Add permissions to AndroidManifest.xml

Open `android/app/src/main/AndroidManifest.xml` and add these lines
**inside `<manifest>`**, before `<application>`:

```xml
<!-- Microphone — speech_to_text (on-device only, no audio uploaded) -->
<uses-permission android:name="android.permission.RECORD_AUDIO"/>

<!-- Internet — RevenueCat subscription verification -->
<uses-permission android:name="android.permission.INTERNET"/>
```

## 4. RevenueCat API key (build time)

The key is not in the source. Pass it when building:

```bash
flutter run --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
flutter build appbundle --release --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
```

Without it the app runs with purchases unavailable (free content only).
Get it from app.revenuecat.com → Project → API keys → Public app-specific.
See docs/BILLING_TESTING.md.

## 5. Install dependencies

```bash
flutter pub get
```

## 6. Run code generation (freezed + riverpod + hive)

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:
- `*.freezed.dart` — immutable models
- `*.g.dart`       — Riverpod providers + Hive adapters + JSON serialisation

## 7. Add your Rive character

Place your exported Rive file at `assets/rive/aiko.riv`.
The state machine must be named **`Aiko_Controller`** with two inputs:
- `emotion` (Number) — 0=normal 1=happy 2=excited 3=curious 4=celebrate 5=sad
- `isTalking` (Boolean)

Until the file is ready, `AikoWidget` automatically shows the emoji fallback.

## 8. Audio

Placeholder mp3s for en/hi/te are committed. Studio recordings replace them
via `tools/ingest_recordings.py` — see docs/VOICE_PRODUCTION.md.
`RELEASE=1 flutter test` fails until every line is a studio recording and
the Hindi/Telugu translations are reviewed (docs/TRANSLATION_REVIEW.md).
Device QA: docs/RELEASE_QA.md.

## 9. Release signing

Store builds need the Play upload key: see docs/release/SIGNING.md
(`tools/create_upload_key.sh`, then `REQUIRE_UPLOAD_KEY=true flutter build appbundle --release`).

## 10. Run

```bash
flutter run
```

---

## Architecture notes

- **No code to change per episode** — add a new JSON file in `assets/episodes/`
- **Episode IDs**: `pf_` = Pattern Forest, `ml_` = Music Lab, `gc_` = Gadget City
- **Privacy**: mic is on-device only; no audio or transcript leaves the device
- **PIN**: Parent Dashboard is PIN-gated; first visit prompts to set a 4-digit PIN
- **Subscription**: RevenueCat syncs to `SubscriptionState` in Hive on each launch

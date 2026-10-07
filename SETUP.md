# AI Explorer — Setup

> **Toolchain:** use Flutter **3.27.x** (Dart 3.6). Newer SDKs (Dart 3.13+) crash the pinned `analyzer`/`riverpod_generator`.
> Models are persisted to Hive as JSON strings (no Hive adapters / hive_generator).
> Steps 1–3 (flutter create + manifest permissions) are still required; `android/` is not committed.

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

## 4. Add your RevenueCat API key

Open `lib/main.dart` and replace the placeholder:

```dart
const _kRevenueCatKey = 'YOUR_REVENUECAT_PUBLIC_SDK_KEY';
```

Get it from app.revenuecat.com → Project → API keys → Public app-specific.

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

## 8. Add placeholder audio files

The app won't crash without audio files — `AudioService` catches the error.
Add real `.mp3` files to `assets/audio/en/` using the naming convention:

```
assets/audio/en/{line_id}.mp3
e.g. assets/audio/en/pf_ep01_s1_intro.mp3
```

## 9. Run

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

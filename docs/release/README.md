# Release gate

App: **AI Explorer** by **Yasvar Labs** (`com.yasvarlabs.aiexplorer`). Listing draft: docs/release/STORE_LISTING.md.

`RELEASE=1 flutter test` is the go/no-go check. It must end with **zero
failures**. It fails until all of these are true:

| Gate | Checked by | Unblocked by |
|---|---|---|
| Studio voice for every line, en/hi/te, one actor per language | `test/release_audio_test.dart` | `tools/ingest_recordings.py` (docs/VOICE_PRODUCTION.md) |
| Aiko character file present and meets the contract | `test/aiko_rive_contract_test.dart` | animator delivers `assets/rive/aiko.riv` (docs/AIKO_CHARACTER.md) |
| Hindi and Telugu reviewed by native speakers (+ child-safety reviewer) | `test/localization_test.dart` | `lib/l10n/review_status.dart` (docs/TRANSLATION_REVIEW.md) |
| Google Play billing tested for real | `test/release_signoff_test.dart` | `docs/release/signoff.json` → `billing` |
| Real-device QA passed | `test/release_signoff_test.dart` | `docs/release/signoff.json` → `device_qa` |
| Release signing with the Play upload key | `test/release_signing_test.dart` + CI `android-build` | `tools/create_upload_key.sh`, GitHub secrets, Play App Signing enrolment (docs/release/SIGNING.md) |
| Privacy policy reviewed, dated, contact set (and hosted for the Play listing) | `test/privacy_policy_test.dart` | legal review of `assets/legal/privacy_policy_en.md`; host the same text at the URL given in Play Console |
| Target API 36 (Play requirement for new apps since 2026-08-31) | `test/release_signoff_test.dart` | done: Flutter 3.47.6 toolchain, `compileSdk`/`targetSdk = 36` pinned in `android/app/build.gradle.kts`, CI `android-build` job builds the APK/AAB and checks its targetSdk; Android 16 behaviour still needs device QA |

Never flip a flag to make the gate pass. Each sign-off records who did the
work, when, and on which build, so it can be audited later.

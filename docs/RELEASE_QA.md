# Release QA checklist (real devices)

Automated tests cover the logic (`flutter test`, ~220 tests) but **none of this
has been run on a physical device yet**. Run every section on a release build
installed from the Play **internal testing** track:

```bash
flutter build appbundle --release --dart-define=REVENUECAT_ANDROID_KEY=goog_…
```

Record device, Android version, build number, tester and result for each row.

## Device matrix (minimum)

| Class | Example | RAM | Android |
|---|---|---|---|
| Low-end | Redmi A-series / Samsung Galaxy A0x / Android Go device | 2–3 GB | 12 or 13 |
| Mid | Samsung Galaxy A3x/A5x, Redmi Note | 4–6 GB | 14 |
| Current | Pixel 8/9 or equivalent | 8 GB+ | 15 and 16 |
| Small screen | any device set to 360×640 dp (Display size: largest) | — | any |

Cover **Android 12, 13, 14, 15 and 16** across the matrix.

## 1. Install, first run, languages
- [ ] Fresh install → onboarding → pick each of English / हिन्दी / తెలుగు → text switches at once
- [ ] Episode audio, titles, buttons and rewards appear in the chosen language
- [ ] Language survives app restart; can be changed in the parent dashboard
- [ ] Hindi and Telugu text renders correctly (conjuncts, vowel signs) on every device's default font

## 2. Small screens (360×640 dp) and large text
- [ ] Every screen in every language: no clipped or overlapping text, all buttons reachable
- [ ] Repeat with system font size at maximum (accessibility)
- [ ] Rhythm game (6 items) fits in one row; answer buttons large enough for a 5-year-old (≥48 dp)

## 3. Low-end performance
- [ ] Cold start to onboarding < 3 s on the low-end device
- [ ] No dropped frames > 1 s during episode steps (Aiko animation, reward animation)
- [ ] Play all 3 episodes back-to-back: no slowdown, no crash, memory stable (Android Studio profiler)
- [ ] APK/AAB download size noted; under 50 MB

## 4. Offline
- [ ] Airplane mode from first launch: onboarding, Pattern Forest episodes play fully
- [ ] Speaking steps work offline (on-device recogniser) — or are skipped cleanly if no offline model
- [ ] Premium bought earlier stays unlocked offline; dashboard Upgrade/Restore show "unavailable" messages, no crash

## 5. Microphone
- [ ] First speaking step: system permission prompt appears (parent present)
- [ ] **Permission denied:** episode skips the speaking step immediately, no frozen "Say something" chip
- [ ] **Permission permanently denied** ("don't ask again"): same, every episode
- [ ] Permission revoked later in Settings → return to app: no crash
- [ ] No offline speech model for hi/te on the device: speaking step skipped, not stuck
- [ ] Parent turns "Voice answers" off: mic never opens, speaking steps skipped
- [ ] Verify (logcat / network inspector) no audio is sent off-device

## 6. Audio interruption
- [ ] Incoming phone call during a line: Aiko pauses; after the call she resumes the same line
- [ ] Alarm / timer goes off mid-line: pauses and resumes
- [ ] Another app plays music while the episode is open: episode pauses, no overlap
- [ ] Bluetooth headphones disconnect mid-line: no crash, no loud speaker blast
- [ ] Volume buttons control media volume; mute switch respected

## 7. Background / resume
- [ ] Home button mid-line → wait 1 min → return: same line continues, episode did not advance on its own
- [ ] Home while Aiko waits for a spoken answer → wait > timeout → return: mic re-opens, no fallback played in background
- [ ] Lock screen / screen off and back: same as above
- [ ] App killed by the system in background (Developer options → don't keep activities): reopen without crash, progress of completed episodes kept
- [ ] Recent-apps switch during a game step: game still answerable

## 8. Repeated / rapid child taps
- [ ] Mash the screen during a tap step: advances exactly one step
- [ ] Tap the correct game answer many times quickly: advances once
- [ ] Spam wrong answers: game stays, encouraging audio plays, no crash
- [ ] Double-tap world cards, "Next Adventure", back buttons: no duplicate screens, no crash
- [ ] Mash the PIN keypad: never more than 4 digits; lockout after 3 wrong entries

## 9. Parent area and premium
- [ ] Fresh install → parent area → grown-up check (number words) required before creating a PIN
- [ ] 3 wrong PINs → locked; leaving, restarting, rebooting, **changing the device date/time** do not unlock early
- [ ] Locked world (Music Lab) for a free user: "ask a grown-up" only — no Play sheet from child screens
- [ ] Every case in `docs/BILLING_TESTING.md` passes

## 10. Content and safety
- [ ] Every line in every language heard in context by a native speaker (after studio recordings)
- [ ] Safety phrases in each language trigger the calm "tell a grown-up" line; parent dashboard count increases
- [ ] Ordinary answers ("I don't know", colours, shapes) never trigger the safety line

## 11. Android version specifics
- [ ] Android 12: app splash, exported activity, mic permission prompt
- [ ] Android 13+: per-app language setting does not conflict with the in-app language
- [ ] Android 14+: no foreground-service or exact-alarm warnings in logcat
- [ ] Android 15/16: edge-to-edge — no content under status/navigation bars on any screen
- [ ] Android 16: predictive back gesture on every screen behaves (no exit mid-episode without confirmation, no back into a locked dashboard)

# Aiko character (Rive) — animator spec

The app loads **`assets/rive/aiko.riv`**. Until it exists the app shows an emoji
stand-in and logs an error; the release gate (`RELEASE=1 flutter test`) fails.

## Contract (checked by `test/aiko_rive_contract_test.dart`)

| Item | Value |
|---|---|
| File | `assets/rive/aiko.riv` (Rive runtime 7.x format, plays on rive-flutter 0.13) |
| Artboard | any name; the first artboard is used |
| State machine | **`Aiko_Controller`** |
| Number input | **`emotion`** — pose index, see below |
| Boolean input | **`isTalking`** — true exactly while a voice line plays |

No other inputs are required; extra inputs are ignored.

## The six states

| State | How the app selects it | Used when |
|---|---|---|
| `idle` | `emotion = 0` | calm narration, waiting, safety line |
| `excited` | `emotion = 1` | intros, praise, correct answers |
| `curious` | `emotion = 2` | questions, puzzles, "what comes next?" |
| `celebrate` | `emotion = 3` | rewards / badges |
| `oops` | `emotion = 4` | wrong answer — playful, never sad or scolding |
| `talking` | `isTalking = true` on top of the current pose | every line, for its exact duration |

`talking` must layer mouth/gesture motion over whichever pose is active (use a
separate layer in the state machine), and return to the pose's resting loop
when `isTalking` goes false. Pose changes must blend (≤ 250 ms), never pop.

## Art direction

- Friendly robot girl, readable at 240×240 dp on a 360×640 phone.
- Loops ≤ 3 s; total file ≤ 500 KB; no embedded fonts, no CDN assets.
- No flashing faster than 3 Hz (photosensitivity), no frightening expressions.
- Test on a low-end device: steady 60 fps (or 30 fps minimum) while talking.

## Who drives it

The episode engine: each line's pose comes from the episode JSON
(`lib/curriculum/episode_lines.dart`), and `isTalking` follows audio playback
(`EpisodeController._play`). Voice actors are directed with the same pose per
line (`docs/recording/script_{lang}.csv`).

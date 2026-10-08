# Hindi / Telugu review

**Every Hindi and Telugu text in the app is a draft written without a native
speaker. None of it may ship until reviewed.** `RELEASE=1 flutter test` fails
until `lib/l10n/review_status.dart` marks a language reviewed (with reviewer
name and date).

One episode logic serves every language: episode JSON holds ids, not text;
each language supplies text keyed by those ids.

## Worksheets (start here)

`docs/review/review_hi.csv` and `docs/review/review_te.csv` list **every**
item below, one row each, with a stable `id`, the English reference, the
current text and a `SAFETY` flag. Reviewers fill `reviewer_ok (Y/N)`,
`correction` and `reviewer_notes`, and send the sheet back; a developer
applies corrections at the source the `id` names
(`ui.*`/`reward.*` → `lib/l10n/strings.dart`, `title.*` → episode JSON,
`audio.*` → `docs/audio_script_{lang}.csv`, `keyword.*` →
`intent_router.dart`, `safety.*` → `safety_layer.dart`), then regenerates:

```bash
UPDATE_REVIEW=1 flutter test test/review_sheet_test.dart
```

CI fails if a sheet is out of date, so reviewers always see current content.
**Every `SAFETY` row needs a child-safety reviewer as well as a native
speaker.** Latin-script keywords/phrases appear in both sheets (they may be
English or romanised Hindi/Telugu); check the ones in your language.

## What to review, per language

| Item | Where | Reviewer |
|---|---|---|
| Aiko's dialogue (25 lines) | `docs/audio_script_{hi,te}.csv` — compare with `docs/audio_script_en.csv` | native speaker |
| Safety line `safety_tell_grownup` | same CSVs | native speaker **and** child-safety reviewer |
| Buttons, hints, world names, rewards, badges, lock messages | `lib/l10n/strings.dart` (`AppStrings.hi`, `AppStrings.te`) | native speaker |
| Episode titles | `assets/episodes/*/*.json` → `title.hi`, `title.te` | native speaker |
| Speech keywords (what a child might say) | `lib/core/speech/intent_router.dart` | native speaker, ideally with recordings of children |
| Safety phrases (disclosure + personal info) | `lib/core/safety/safety_layer.dart` | native speaker **and** child-safety reviewer |

## What to check

- Natural for a 5–7-year-old; not literal translation.
- Aiko is feminine in Hindi (सिखाऊँगी, चाहती हूँ). Child-addressing forms are
  gender-neutral where the language allows; flag any that aren't.
- Speech keywords: what children actually say, including common
  romanised/English mixes, and nothing that also appears in everyday answers
  (e.g. Hindi पता = address, but also पता नहीं = I don't know).
- Safety phrases: catch real disclosures; over-triggering a gentle
  "tell a grown-up" is acceptable, missing one is not.
- Consistent terms: पैटर्न/ప్యాటర్న్, डेटा/డేటా, AI.

## Sign-off

When a language passes: remove "DRAFT … needs native-speaker review" from its
CSV notes, set `TranslationReview(reviewed: true, reviewer: '…', date: '…')`,
then record the voice lines (docs/VOICE_PRODUCTION.md) from the reviewed text.

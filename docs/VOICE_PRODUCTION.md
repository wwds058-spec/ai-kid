# Aiko voice production

The committed mp3s are **machine placeholders** (espeak-ng). They are not the
product voice and the release test (`RELEASE=1 flutter test`) fails until every
line in every language is a studio recording.

## Casting

- One voice actor per language (en: Indian English, hi, te), female, warm,
  playful, reads as a friendly older sibling to a 5–7-year-old.
- Same character across languages: match energy and pitch range between the
  three actors; record a reference line (`pf_ep01_s1_intro`) first and share it.
- Consent and rights: written buy-out covering app use, store listing and
  marketing, all territories, no AI voice-cloning of the recordings.

## Script and emotion

`python3 tools/build_recording_script.py` writes `docs/recording/script_{lang}.csv`
— the session sheet. Every row has:

| column | meaning |
|---|---|
| `file` | exact filename to deliver |
| `emotion` | Aiko's on-screen emotion while the line plays |
| `direction` | acting note for that emotion |
| `english_reference` | the English line, so meaning matches across languages |
| `text` | what to read |

Emotions are Aiko's five animation poses (`idle`, `excited`, `curious`,
`celebrate`, `oops`); her sixth state, `talking`, is on for every line while
it plays. Each line's emotion comes from the episode JSON (step emotion;
replies default `excited`; wrong-answer `oops`; fallbacks and shared lines
`idle`) and `test/audio_emotion_test.dart` keeps the script equal
to what the app animates.

Rows marked **SAFETY** (`safety_tell_grownup`) are read calmly and warmly,
never alarmed, and need sign-off from a child-safety reviewer in each language.

## Delivery spec

- WAV 48 kHz/24-bit mono (FLAC also accepted), one file per line, named
  `{line_id}.wav`, no processing beyond gentle de-noise.
- 0.4–30 s per line, ~0.3 s room tone either side, no mouth clicks/breaths at edges.
- Record 2 takes per line; deliver the chosen take only.

## Ingest

```bash
python3 tools/ingest_recordings.py --lang hi --src ~/delivery/hi --talent "<voice actor>" \
    --detail "Studio: <studio>, Session: <date>"
```

Rejects the whole delivery (writes nothing) on unknown ids, unreadable files
or bad durations. Otherwise trims silence, normalises to −16 LUFS / −1.5 dBTP,
encodes mono mp3 96 kbps, writes `assets/audio/{lang}/{line_id}.mp3` and records
it as `studio` with its sha256 in `docs/audio_manifest_{lang}.json`.
The placeholder generator never overwrites a `studio` line.

## Acceptance (per language)

- [ ] `RELEASE=1 flutter test test/release_audio_test.dart` passes
- [ ] Native speaker listened to every line in the app, in context
- [ ] Safety line approved by a child-safety reviewer
- [ ] Loudness consistent across lines and languages (ingest normalises; spot-check)

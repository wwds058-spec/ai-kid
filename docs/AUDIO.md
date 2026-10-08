# Audio lines

Every line the app can play is scripted once per language:

| Language | Script | Audio folder |
|---|---|---|
| English | `docs/audio_script_en.csv` | `assets/audio/en/` |
| Hindi | `docs/audio_script_hi.csv` | `assets/audio/hi/` |
| Telugu | `docs/audio_script_te.csv` | `assets/audio/te/` |

Each file is `assets/audio/{lang}/{line_id}.mp3`.

- The English text is a draft. **The Hindi and Telugu text are draft
  translations and need native-speaker review** (marked in each row's notes).
- Rows marked SAFETY (`safety_tell_grownup`) must be approved by someone
  qualified in child safety, in every language, before release.
- If a localised file is missing at runtime the app plays the English one
  rather than staying silent. The tests make sure this never happens in a build.

## Placeholder audio (development only)

All committed mp3s are **machine-generated placeholders** so episodes can be
played end to end on a device. They are not for release.

```bash
pip install edge-tts                    # optional; needs internet
sudo apt-get install espeak-ng ffmpeg   # offline fallback
python3 tools/gen_placeholder_audio.py --force              # all languages
python3 tools/gen_placeholder_audio.py --lang hi --force    # one language
```

Voices: edge-tts `en-IN-NeerjaNeural`, `hi-IN-SwaraNeural`, `te-IN-ShrutiNeural`.
If edge-tts is unreachable the script uses espeak-ng (`en-us`, `hi`, `te`) for
the whole run. The committed files were made with the espeak fallback because
the build environment blocks edge-tts; re-run on a machine with internet for
the neural voices.

`RELEASE=1 flutter test` fails while any `assets/audio/{lang}/PLACEHOLDER.txt`
exists. Delete the placeholders and that file when real recordings are added.

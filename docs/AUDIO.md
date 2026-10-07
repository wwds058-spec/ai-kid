# Audio lines

`audio_script_en.csv` lists every line the app can play (draft English text).
Record or generate each as `assets/audio/{lang}/{line_id}.mp3` for `en`, `hi`, `te`.

- Missing files don't crash the app; they are skipped with a log message.
- `test/audio_script_test.dart` fails if an episode references a line id that
  is not in the CSV, so add a row whenever you add a step.
- Rows marked SAFETY must be reviewed by someone qualified in child safety
  before release.

## Placeholder audio (development only)

`assets/audio/en/*.mp3` are **machine-generated placeholders** so episodes can be
played end to end on a device. They are not for release.

Regenerate every line from the CSV:

```bash
pip install edge-tts            # optional; needs internet
sudo apt-get install espeak-ng ffmpeg   # offline fallback
python3 tools/gen_placeholder_audio.py --force
```

The script uses `edge-tts` with `en-IN-NeerjaNeural`; if that service is
unreachable it falls back to `espeak-ng` for the whole run (one consistent
voice). The committed files were generated with the espeak fallback because
the build environment blocks edge-tts. Re-run on a machine with internet to
get the Neerja voice.

`RELEASE=1 flutter test` fails while `assets/audio/en/PLACEHOLDER.txt` exists.
Delete the placeholders and that file when real recordings are added.

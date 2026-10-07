# Audio lines

`audio_script_en.csv` lists every line the app can play (draft English text).
Record or generate each as `assets/audio/{lang}/{line_id}.mp3` for `en`, `hi`, `te`.

- Missing files don't crash the app; they are skipped with a log message.
- `test/audio_script_test.dart` fails if an episode references a line id that
  is not in the CSV, so add a row whenever you add a step.
- Rows marked SAFETY must be reviewed by someone qualified in child safety
  before release.

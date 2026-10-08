# Adding an episode

1. **JSON** — `assets/episodes/{world}/{id}.json`, where `id` is
   `{prefix}_epNN` (`pf_` Pattern Forest, `ml_` Music Lab, `gc_` Gadget City).
2. **Catalog** — add `CatalogEpisode('{id}', premium: ...)` to the world in
   `lib/curriculum/episode_catalog.dart`, in play order. `premium` must match
   the JSON.
3. **Audio** — add every line to `docs/audio_script_{en,hi,te}.csv`, then run
   `python3 tools/gen_placeholder_audio.py`.
4. Run `flutter test`.

`test/episode_content_test.dart` and `test/audio_script_test.dart` fail if:

- the id doesn't match the file name, folder, prefix or JSON `world`
- the catalog and the files on disk disagree, or the world's folder is missing
  from `pubspec.yaml` (it wouldn't be bundled)
- the catalog and JSON disagree on `premium`
- the JSON has an unknown key (a typo like `fallbak` would otherwise be ignored)
- a title is missing for any of en, hi, te
- step ids repeat, or there isn't exactly one reward step, last
- an emotion isn't one Aiko's Rive state machine knows
- a play step uses an unknown game, its answer isn't among the choices, it has
  no single ❓, more than 6 items, or no `onWrong`
- a speak step has no intents or fallback, a duplicate or unknown intent, or a
  timeout outside 3–30s
- a reward badge isn't in `lib/curriculum/badges.dart` (with names in every
  language in `lib/l10n/strings.dart`)
- audio ids repeat, aren't prefixed with the episode id, or any line lacks
  script text or an mp3 in any language
- a script has lines nothing plays, or mp3s with no script line

## Premium

Premium is per episode. A world is **open** if the child can play at least one
of its episodes, **locked** (🔒, "ask a grown-up") if every episode needs
Premium, and **coming soon** if it has none. Locked content never offers a
purchase to the child; buying happens only in the PIN-protected parent dashboard.

import 'package:ai_explorer/core/rive/aiko_widget.dart';
import 'package:ai_explorer/curriculum/episode_lines.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content.dart';

/// The voice actor is directed with the emotion in docs/audio_script_en.csv
/// (via tools/build_recording_script.py); the app animates Aiko with the
/// emotion derived from the episode JSON. They must be the same.
void main() {
  final scripted = loadAudioScriptColumn('en', 'emotion');
  final lines = [
    for (final f in loadEpisodeFiles()) ...linesOf(f.script),
    ...kSharedLines,
  ];

  test('every line has an animation emotion Aiko supports', () {
    for (final l in lines) {
      expect(AikoWidget.emotionIndex.keys, contains(l.emotion), reason: l.id);
    }
  });

  test('recording emotion matches the on-screen emotion for every line', () {
    for (final l in lines) {
      expect(scripted[l.id], l.emotion,
          reason: '${l.id}: script says ${scripted[l.id]}, '
              'app shows ${l.emotion} (${l.kind.name})');
    }
  });

  test('recording script covers exactly the playable lines', () {
    expect(scripted.keys.toSet(), lines.map((l) => l.id).toSet());
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:ai_explorer/curriculum/models/episode_script.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ids the engine plays regardless of episode content.
const _sharedIds = {'generic_fallback', 'generic_too_long', 'safety_tell_grownup'};

Set<String> _csvIds() => File('docs/audio_script_en.csv')
    .readAsLinesSync()
    .skip(1)
    .where((l) => l.trim().isNotEmpty)
    .map((l) => l.split(',').first)
    .toSet();

void main() {
  test('every audio id used by an episode (and the engine) is in the script',
      () {
    final needed = <String>{..._sharedIds};
    for (final f in Directory('assets/episodes')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
      final ep = EpisodeScript.fromJson(
          jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
      for (final s in ep.steps) {
        needed.add(s.audio);
        if (s.onWrong != null) needed.add(s.onWrong!);
        if (s.fallback != null) needed.add(s.fallback!);
        needed.addAll(s.intents.map((i) => i.audio));
      }
    }
    expect(_csvIds().containsAll(needed), isTrue,
        reason: 'missing: ${needed.difference(_csvIds())}');
  });

  test('script has no stale ids that nothing plays', () {
    final used = <String>{..._sharedIds};
    for (final f in Directory('assets/episodes')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
      final ep = EpisodeScript.fromJson(
          jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
      for (final s in ep.steps) {
        used.add(s.audio);
        if (s.onWrong != null) used.add(s.onWrong!);
        if (s.fallback != null) used.add(s.fallback!);
        used.addAll(s.intents.map((i) => i.audio));
      }
    }
    expect(used.containsAll(_csvIds()), isTrue,
        reason: 'stale: ${_csvIds().difference(used)}');
  });
}

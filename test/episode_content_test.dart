import 'dart:convert';
import 'dart:io';

import 'package:ai_explorer/core/speech/intent_router.dart';
import 'package:ai_explorer/curriculum/models/episode_script.dart';
import 'package:flutter_test/flutter_test.dart';

/// Content lint for every episode JSON, so a typo in a new episode fails CI
/// instead of silently falling back to generic audio on a child's device.
void main() {
  final files = Directory('assets/episodes')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'));

  test('at least one episode exists', () => expect(files, isNotEmpty));

  for (final file in files) {
    group(file.path, () {
      final ep = EpisodeScript.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);

      test('id matches file name and world prefix', () {
        expect(file.path.endsWith('${ep.id}.json'), isTrue);
        expect(file.path, contains('/${ep.world}/'));
      });

      test('step ids and audio ids are unique', () {
        final ids = ep.steps.map((s) => s.id).toList();
        expect(ids.toSet().length, ids.length);
        final audio = [
          for (final s in ep.steps) ...[
            s.audio,
            if (s.onWrong != null) s.onWrong!,
            if (s.fallback != null) s.fallback!,
            ...s.intents.map((i) => i.audio),
          ]
        ];
        expect(audio.toSet().length, audio.length);
      });

      test('steps carry what their type needs', () {
        for (final s in ep.steps) {
          switch (s.type) {
            case StepType.play:
              expect(s.advance, AdvanceMode.correctAnswer, reason: s.id);
              expect(s.gameConfig?.answer, isNotNull, reason: s.id);
            case StepType.speak:
              expect(s.advance, AdvanceMode.speech, reason: s.id);
              expect(s.intents, isNotEmpty, reason: s.id);
              expect(s.fallback, isNotNull, reason: s.id);
            case StepType.reward:
              expect(s.badge, isNotNull, reason: s.id);
            case StepType.watch:
              expect(s.advance, anyOf(AdvanceMode.auto, AdvanceMode.tap),
                  reason: s.id);
          }
        }
      });

      test('speak intents are ones the router understands', () {
        for (final s in ep.steps) {
          for (final i in s.intents) {
            expect(IntentRouter.knownIntents, contains(i.match),
                reason: '${s.id}: ${i.match}');
          }
        }
      });

      test('title has an English entry', () {
        expect(ep.title['en'], isNotEmpty);
      });
    });
  }
}

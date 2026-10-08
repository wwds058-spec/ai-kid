import 'dart:io';

import 'package:ai_explorer/core/rive/aiko_widget.dart';
import 'package:ai_explorer/core/speech/intent_router.dart';
import 'package:ai_explorer/curriculum/badges.dart';
import 'package:ai_explorer/curriculum/episode_catalog.dart';
import 'package:ai_explorer/curriculum/models/episode_script.dart';
import 'package:ai_explorer/l10n/strings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content.dart';

/// Content lint: a typo or missing asset in an episode fails CI instead of
/// silently degrading (generic audio, stuck game, dead world) on a device.

const _games = {'pattern_tap'};
const _topKeys = {'id', 'world', 'title', 'premium', 'steps'};
const _stepKeys = {
  'id', 'type', 'audio', 'emotion', 'scene', 'advance', 'game', 'gameConfig',
  'onWrong', 'intents', 'fallback', 'timeoutSeconds', 'badge',
};
const _gameConfigKeys = {'items', 'answer', 'extra'};
const _intentKeys = {'match', 'audio', 'emotion'};

void main() {
  final files = loadEpisodeFiles();
  final scripts = {for (final l in kLanguages) l: loadAudioScript(l)};

  group('catalog', () {
    test('at least one episode exists', () => expect(files, isNotEmpty));

    test('world ids and prefixes are unique', () {
      final ids = EpisodeCatalog.worlds.map((w) => w.id).toList();
      final prefixes = EpisodeCatalog.worlds.map((w) => w.prefix).toList();
      expect(ids.toSet().length, ids.length);
      expect(prefixes.toSet().length, prefixes.length);
    });

    test('episode ids are unique, well-formed and in their prefix world', () {
      final all = [
        for (final w in EpisodeCatalog.worlds)
          for (final e in w.episodes) (w, e),
      ];
      expect(all.map((p) => p.$2.id).toSet().length, all.length,
          reason: 'duplicate id in catalog');
      for (final (w, e) in all) {
        expect(EpisodeCatalog.isValidId(e.id), isTrue,
            reason: '${e.id}: must look like ${w.prefix}_epNN');
        expect(EpisodeCatalog.worldOf(e.id)?.id, w.id,
            reason: '${e.id} is listed under ${w.id} but its prefix says otherwise');
      }
    });

    test('catalog lists exactly the episode files on disk', () {
      final onDisk = {for (final f in files) f.fileId};
      final inCatalog = {
        for (final w in EpisodeCatalog.worlds) ...w.episodes.map((e) => e.id),
      };
      expect(inCatalog.difference(onDisk), isEmpty,
          reason: 'in catalog but no JSON file');
      expect(onDisk.difference(inCatalog), isEmpty,
          reason: 'JSON file not in catalog (unreachable in the app)');
    });

    test('every world with episodes has its asset folder in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final w in EpisodeCatalog.worlds.where((w) => w.episodes.isNotEmpty)) {
        expect(pubspec, contains('- assets/episodes/${w.id}/'),
            reason: '${w.id} episodes would not be bundled');
      }
      for (final lang in kLanguages) {
        expect(pubspec, contains('- assets/audio/$lang/'));
      }
    });

    test('every world and badge has a name in every language', () {
      for (final lang in kLanguages) {
        final t = AppStrings.of(lang);
        expect(t, same(AppStrings.all[lang]), reason: '$lang strings missing');
        for (final w in EpisodeCatalog.worlds) {
          expect(t.worldNames[w.id], isNotEmpty, reason: '$lang: ${w.id}');
        }
        expect(t.badges.keys.toSet(), kBadgeEmoji.keys.toSet(),
            reason: '$lang badge names out of sync with kBadgeEmoji');
      }
    });
  });

  for (final f in files) {
    final ep = f.script;
    group(f.file.path, () {
      test('id matches file name, folder, prefix and JSON world', () {
        expect(ep.id, f.fileId);
        expect(EpisodeCatalog.isValidId(ep.id), isTrue);
        final world = EpisodeCatalog.worldOf(ep.id);
        expect(world, isNotNull, reason: 'unknown prefix');
        expect(f.folder, world!.id);
        expect(ep.world, world.id);
      });

      test('premium flag matches the catalog', () {
        expect(EpisodeCatalog.episode(ep.id)?.premium, ep.premium,
            reason: 'catalog and JSON disagree on premium');
      });

      test('no unknown JSON keys (typos would be silently ignored)', () {
        expect(_topKeys.containsAll(f.raw.keys), isTrue,
            reason: '${f.raw.keys.toSet().difference(_topKeys)}');
        for (final step in (f.raw['steps'] as List).cast<Map<String, dynamic>>()) {
          final where = 'step ${step['id']}';
          expect(_stepKeys.containsAll(step.keys), isTrue,
              reason: '$where: ${step.keys.toSet().difference(_stepKeys)}');
          final gc = step['gameConfig'] as Map<String, dynamic>?;
          if (gc != null) {
            expect(_gameConfigKeys.containsAll(gc.keys), isTrue, reason: where);
          }
          for (final i in (step['intents'] as List? ?? const [])
              .cast<Map<String, dynamic>>()) {
            expect(_intentKeys.containsAll(i.keys), isTrue, reason: where);
          }
        }
      });

      test('has a title in every language', () {
        expect(ep.title.keys.toSet(), kLanguages.toSet());
        for (final v in ep.title.values) {
          expect(v.trim(), isNotEmpty);
        }
      });

      test('steps: unique ids, one reward step and it is last', () {
        expect(ep.steps, isNotEmpty);
        final ids = ep.steps.map((s) => s.id).toList();
        expect(ids.toSet().length, ids.length);
        expect(ep.steps.where((s) => s.type == StepType.reward), hasLength(1));
        expect(ep.steps.last.type, StepType.reward);
      });

      test('steps carry what their type needs', () {
        for (final s in ep.steps) {
          expect(AikoWidget.emotionIndex.keys, contains(s.emotion),
              reason: '${s.id}: unknown emotion ${s.emotion}');
          switch (s.type) {
            case StepType.play:
              expect(s.advance, AdvanceMode.correctAnswer, reason: s.id);
              expect(_games, contains(s.game), reason: '${s.id}: game ${s.game}');
              expect(s.gameConfig?.answer, isNotNull, reason: s.id);
              // The game offers the pattern's non-❓ items as choices, so the
              // answer must be one of them or the step can't be completed.
              final choices = s.gameConfig!.items.where((i) => i != '❓').toSet();
              expect(choices, contains(s.gameConfig!.answer), reason: s.id);
              expect(s.gameConfig!.items.where((i) => i == '❓'), hasLength(1),
                  reason: '${s.id}: exactly one ❓');
              expect(s.gameConfig!.items.length, lessThanOrEqualTo(6),
                  reason: '${s.id}: longer rows overflow narrow phones');
              expect(s.onWrong, isNotNull, reason: s.id);
            case StepType.speak:
              expect(s.advance, AdvanceMode.speech, reason: s.id);
              expect(s.intents, isNotEmpty, reason: s.id);
              expect(s.fallback, isNotNull, reason: s.id);
              expect(s.timeoutSeconds, inInclusiveRange(3, 30), reason: s.id);
              final matches = s.intents.map((i) => i.match).toList();
              expect(matches.toSet().length, matches.length,
                  reason: '${s.id}: duplicate intent');
              for (final m in matches) {
                expect(IntentRouter.knownIntents, contains(m),
                    reason: '${s.id}: $m');
              }
            case StepType.reward:
              expect(kBadgeEmoji.keys, contains(s.badge),
                  reason: '${s.id}: unknown badge ${s.badge}');
            case StepType.watch:
              expect(s.advance, anyOf(AdvanceMode.auto, AdvanceMode.tap),
                  reason: s.id);
          }
        }
      });

      test('audio ids are unique and namespaced to the episode', () {
        final ids = f.audioIds;
        expect(ids.toSet().length, ids.length);
        for (final id in ids) {
          expect(id, startsWith('${ep.id}_'),
              reason: '$id: prefix audio ids with the episode id so two '
                  'episodes can never share a recording');
        }
      });

      for (final lang in kLanguages) {
        test('[$lang] every audio line is scripted and has an mp3', () {
          for (final id in [...f.audioIds, ...kSharedAudioIds]) {
            expect(scripts[lang]![id]?.trim(), isNotEmpty,
                reason: 'docs/audio_script_$lang.csv has no text for $id');
            expect(File('assets/audio/$lang/$id.mp3').existsSync(), isTrue,
                reason: 'missing assets/audio/$lang/$id.mp3 '
                    '(run tools/gen_placeholder_audio.py --lang $lang)');
          }
        });
      }
    });
  }
}

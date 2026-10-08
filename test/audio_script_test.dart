import 'dart:io';

import 'package:ai_explorer/curriculum/episode_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content.dart';

void main() {
  final used = {
    ...kSharedAudioIds,
    for (final f in loadEpisodeFiles()) ...f.audioIds,
  };

  for (final lang in kLanguages) {
    group('[$lang] audio script', () {
      final script = loadAudioScript(lang);

      test('has no line ids that nothing plays', () {
        expect(script.keys.toSet().difference(used), isEmpty);
      });

      test('covers every played id with non-empty text', () {
        expect(used.difference(script.keys.toSet()), isEmpty);
        for (final e in script.entries) {
          expect(e.value.trim(), isNotEmpty, reason: e.key);
        }
      });

      test('has no stray mp3s without a script line', () {
        final mp3s = Directory('assets/audio/$lang')
            .listSync()
            .map((e) => e.uri.pathSegments.last)
            .where((n) => n.endsWith('.mp3'))
            .map((n) => n.replaceAll('.mp3', ''))
            .toSet();
        expect(mp3s.difference(script.keys.toSet()), isEmpty);
      });
    });
  }

  test('translations line up with English one-to-one', () {
    final en = loadAudioScript('en').keys.toSet();
    for (final lang in kLanguages) {
      expect(loadAudioScript(lang).keys.toSet(), en, reason: lang);
    }
  });
}

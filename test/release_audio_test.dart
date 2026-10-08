import 'dart:convert';
import 'dart:io';

import 'package:ai_explorer/curriculum/episode_catalog.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content.dart';

/// docs/audio_manifest_{lang}.json records where every shipped mp3 came from.
///
/// Always: the manifest must describe every mp3 exactly (hash match), so a
/// file can't be dropped in or swapped without going through the tools.
/// RELEASE=1: every line must be a studio recording — no placeholders ship.
void main() {
  final isRelease = Platform.environment['RELEASE'] == '1';

  for (final lang in kLanguages) {
    final manifest = jsonDecode(
            File('docs/audio_manifest_$lang.json').readAsStringSync())
        as Map<String, dynamic>;
    final ids = loadAudioScript(lang).keys;

    test('[$lang] manifest matches every mp3 byte for byte', () {
      for (final id in ids) {
        final entry = manifest[id] as Map<String, dynamic>?;
        expect(entry, isNotNull, reason: '$id missing from manifest');
        final bytes = File('assets/audio/$lang/$id.mp3').readAsBytesSync();
        expect(entry!['sha256'], sha256.convert(bytes).toString(),
            reason: '$lang/$id.mp3 changed outside the audio tools');
        expect(entry['source'], anyOf('placeholder', 'studio'), reason: id);
      }
      expect(manifest.keys.toSet().difference(ids.toSet()), isEmpty,
          reason: 'manifest lists lines that no longer exist');
    });

    test('[$lang] every line is a studio recording', () {
      final placeholders = [
        for (final id in ids)
          if ((manifest[id] as Map?)?['source'] != 'studio') id,
      ];
      expect(placeholders, isEmpty,
          reason: '${placeholders.length} placeholder lines in $lang: '
              'ingest studio recordings with tools/ingest_recordings.py');
    }, skip: isRelease ? false : 'only enforced when RELEASE=1');
  }
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Placeholder (machine-generated) audio must never ship.
/// Run with `RELEASE=1 flutter test` (or set RELEASE=1 in the release CI job).
void main() {
  final isRelease = Platform.environment['RELEASE'] == '1';

  test('every line in the script has an English mp3', () {
    final ids = File('docs/audio_script_en.csv')
        .readAsLinesSync()
        .skip(1)
        .where((l) => l.trim().isNotEmpty)
        .map((l) => l.split(',').first);
    for (final id in ids) {
      expect(File('assets/audio/en/$id.mp3').existsSync(), isTrue,
          reason: 'missing assets/audio/en/$id.mp3 '
              '(run tools/gen_placeholder_audio.py)');
    }
  });

  test('no placeholder audio in a release build', () {
    expect(File('assets/audio/en/PLACEHOLDER.txt').existsSync(), isFalse,
        reason: 'assets/audio/en holds machine-generated placeholders - '
            'replace them with real recordings and delete PLACEHOLDER.txt');
  }, skip: isRelease ? false : 'only enforced when RELEASE=1');
}

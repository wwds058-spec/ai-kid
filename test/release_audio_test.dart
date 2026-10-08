import 'dart:io';

import 'package:ai_explorer/curriculum/episode_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Placeholder (machine-generated) audio must never ship.
/// Run with `RELEASE=1 flutter test` (or set RELEASE=1 in the release CI job).
void main() {
  final isRelease = Platform.environment['RELEASE'] == '1';

  for (final lang in kLanguages) {
    test('[$lang] no placeholder audio in a release build', () {
      expect(File('assets/audio/$lang/PLACEHOLDER.txt').existsSync(), isFalse,
          reason: 'assets/audio/$lang holds machine-generated placeholders - '
              'replace them with real recordings and delete PLACEHOLDER.txt');
    }, skip: isRelease ? false : 'only enforced when RELEASE=1');
  }
}

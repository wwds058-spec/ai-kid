import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Human sign-offs the release depends on (docs/release/signoff.json).
/// Code can't test Google Play billing or physical devices; people do, and
/// record it here. RELEASE=1 refuses to pass without them.
void main() {
  final isRelease = Platform.environment['RELEASE'] == '1';
  final signoff = jsonDecode(File('docs/release/signoff.json').readAsStringSync())
      as Map<String, dynamic>;

  test('sign-off record is well formed', () {
    for (final section in ['billing', 'device_qa']) {
      final s = signoff[section] as Map<String, dynamic>;
      expect(s['passed'], isA<bool>(), reason: section);
      if (s['passed'] == true) {
        for (final field in ['tester', 'date', 'build']) {
          expect(s[field], isA<String>(), reason: '$section.$field');
          expect((s[field] as String).trim(), isNotEmpty, reason: '$section.$field');
        }
      }
    }
  });

  test('Google Play billing test purchase flow has passed', () {
    final b = signoff['billing'] as Map<String, dynamic>;
    expect(b['passed'], isTrue,
        reason: 'run docs/BILLING_TESTING.md on the Play internal track and '
            'record it in docs/release/signoff.json');
  }, skip: isRelease ? false : 'only enforced when RELEASE=1');

  test('real-device QA has passed, incl. a low-end device and Android 12–16', () {
    final q = signoff['device_qa'] as Map<String, dynamic>;
    expect(q['passed'], isTrue,
        reason: 'run docs/RELEASE_QA.md and record it in docs/release/signoff.json');
    final devices = (q['devices'] as List).cast<Map<String, dynamic>>();
    expect(devices.any((d) => d['low_end'] == true), isTrue,
        reason: 'at least one low-end device');
    final versions = devices.map((d) => d['android']).toSet();
    for (final v in [12, 13, 14, 15, 16]) {
      expect(versions, contains(v), reason: 'Android $v not covered');
    }
  }, skip: isRelease ? false : 'only enforced when RELEASE=1');

  test('targets the API level Google Play requires for new apps (36)', () {
    // Play: new apps/updates must target Android 16 (API 36) from
    // 2026-08-31 (extension to 2026-11-01 on request). Pinned explicitly in
    // android/app/build.gradle.kts; CI's android-build job also checks the
    // built APK. Android 16 behaviour must still be verified on device.
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final m = RegExp(r'targetSdk\s*=\s*(\d+)').firstMatch(gradle);
    expect(m, isNotNull,
        reason: 'pin targetSdk = 36 in android/app/build.gradle.kts '
            '(see docs/release/README.md)');
    expect(int.parse(m!.group(1)!), greaterThanOrEqualTo(36));
  }, skip: isRelease ? false : 'only enforced when RELEASE=1');
}

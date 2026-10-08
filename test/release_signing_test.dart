import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Release-signing safety rails (docs/release/SIGNING.md).
void main() {
  test('no signing material is committed', () async {
    final r = await Process.run('git', ['ls-files']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final tracked = (r.stdout as String).split('\n');
    final secret = RegExp(r'(\.jks|\.keystore|\.p12|\.pem|key\.properties|\.keystore\.base64)$');
    expect(tracked.where(secret.hasMatch), isEmpty);
  });

  test('keystores and key.properties are gitignored', () async {
    for (final path in [
      'android/key.properties',
      'upload-keystore.jks',
      'android/app/upload.keystore',
    ]) {
      final r = await Process.run('git', ['check-ignore', '-q', path]);
      expect(r.exitCode, 0, reason: '$path is not ignored');
    }
  });

  group('android/app/build.gradle.kts', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    test('release builds sign with the upload key when configured', () {
      expect(gradle, contains('create("upload")'));
      expect(gradle,
          contains('signingConfigs.getByName(if (hasUploadKey) "upload" else "debug")'));
    });

    test('store builds refuse to fall back to debug signing', () {
      expect(gradle, contains('REQUIRE_UPLOAD_KEY'));
      expect(gradle, contains('throw GradleException('));
    });

    test('no secret values are written into the build file', () {
      expect(RegExp(r'storePassword\s*=\s*"').hasMatch(gradle), isFalse);
      expect(RegExp(r'keyPassword\s*=\s*"').hasMatch(gradle), isFalse);
    });
  });
}

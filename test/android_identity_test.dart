import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// App identity on Google Play. The applicationId is permanent after the
/// first upload, so any change to it must be deliberate.
const kApplicationId = 'com.yasvarlabs.aiexplorer';

void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  test('applicationId and namespace are the Yasvar Labs package', () {
    expect(gradle, contains('applicationId = "$kApplicationId"'));
    expect(gradle, contains('namespace = "$kApplicationId"'));
  });

  test('MainActivity lives in the namespace package (else the app cannot launch)',
      () {
    final path = 'android/app/src/main/kotlin/${kApplicationId.replaceAll('.', '/')}/MainActivity.kt';
    final f = File(path);
    expect(f.existsSync(), isTrue, reason: path);
    expect(f.readAsStringSync(), startsWith('package $kApplicationId\n'));
    expect(manifest, contains('android:name=".MainActivity"'));
  });

  test('no leftover Kotlin sources under an old package', () {
    final kt = Directory('android/app/src/main/kotlin')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.kt'))
        .toList();
    expect(kt, hasLength(1));
  });

  test('launcher label is the product name, not the project id', () {
    expect(manifest, contains('android:label="AI Explorer"'));
  });
}

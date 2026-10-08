import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// A YAML error in a workflow makes GitHub run no jobs at all — CI silently
/// stops testing. Catch it locally.
void main() {
  for (final f in Directory('.github/workflows')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.yml') || f.path.endsWith('.yaml'))) {
    test('${f.path} is valid YAML with jobs and named steps', () {
      final doc = loadYaml(f.readAsStringSync()) as YamlMap;
      final jobs = doc['jobs'] as YamlMap;
      expect(jobs, isNotEmpty);
      for (final job in jobs.values.cast<YamlMap>()) {
        for (final step in (job['steps'] as YamlList).cast<YamlMap>()) {
          expect(step['run'] ?? step['uses'], isNotNull, reason: '$step');
        }
      }
    });
  }

  test('android-build verifies API 36, package and label of the built APK', () {
    final ci = File('.github/workflows/ci.yml').readAsStringSync();
    expect(ci, contains("targetSdkVersion:'36'"));
    expect(ci, contains("package: name='com.yasvarlabs.aiexplorer'"));
    expect(ci, contains("application-label:'AI Explorer'"));
  });
}

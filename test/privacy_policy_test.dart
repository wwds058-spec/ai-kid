import 'dart:io';

import 'package:ai_explorer/core/purchases/purchase_service.dart';
import 'package:ai_explorer/curriculum/episode_controller.dart';
import 'package:ai_explorer/features/parent_dashboard/parent_dashboard_screen.dart';
import 'package:ai_explorer/l10n/parent_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_storage.dart';
import 'support/fake_store.dart';

void main() {
  final policy =
      File('assets/legal/privacy_policy_en.md').readAsStringSync();

  group('policy states what the code does', () {
    test('on-device speech, no recordings sent', () {
      expect(policy, contains('on the device'));
      expect(File('lib/core/speech/speech_service.dart').readAsStringSync(),
          contains('onDevice: true'),
          reason: 'policy promises on-device recognition');
    });

    test('no ads / analytics / tracking SDKs in dependencies', () {
      expect(policy, contains('No ads, no analytics, no tracking'));
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final sdk in [
        'firebase_analytics', 'google_mobile_ads', 'firebase_crashlytics',
        'sentry', 'amplitude', 'mixpanel', 'appsflyer', 'facebook',
      ]) {
        expect(pubspec, isNot(contains(sdk)),
            reason: '$sdk would contradict the privacy policy');
      }
    });

    test('names the subscription processor and only declared permissions', () {
      expect(policy, contains('RevenueCat'));
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      final perms = RegExp(r'uses-permission android:name="([^"]+)"')
          .allMatches(manifest)
          .map((m) => m.group(1))
          .toSet();
      expect(perms, {
        'android.permission.RECORD_AUDIO',
        'android.permission.INTERNET',
      }, reason: 'policy lists Microphone and Internet only');
    });

    test('release: policy reviewed, dated, with a real contact', () {
      expect(policy, isNot(contains('Draft for legal review')));
      expect(policy, isNot(contains('to be set')),
          reason: 'effective date and support email must be filled in');
    }, skip: Platform.environment['RELEASE'] == '1'
        ? false
        : 'only enforced when RELEASE=1');
  });

  testWidgets('parent dashboard opens the bundled policy', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = ProviderContainer(overrides: [
      hiveStorageServiceProvider.overrideWithValue(FakeStorage()),
      storeClientProvider.overrideWithValue(FakeStore()),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c, child: const MaterialApp(home: ParentDashboardScreen())));
    await tester.ensureVisible(find.byKey(const ValueKey('privacy_policy')));
    await tester.tap(find.byKey(const ValueKey('privacy_policy')));
    await tester.pumpAndSettle();
    expect(find.text(ParentStrings.en.privacyPolicy), findsOneWidget);
    expect(find.textContaining('No voice recordings'), findsOneWidget);
  });
}

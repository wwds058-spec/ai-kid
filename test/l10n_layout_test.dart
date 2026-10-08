import 'package:ai_explorer/core/storage/models/child_profile.dart';
import 'package:ai_explorer/curriculum/episode_catalog.dart';
import 'package:ai_explorer/curriculum/episode_controller.dart';
import 'package:ai_explorer/features/onboarding/onboarding_screen.dart';
import 'package:ai_explorer/features/reward/reward_screen.dart';
import 'package:ai_explorer/features/world_map/world_map_screen.dart';
import 'package:ai_explorer/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_storage.dart';

/// Hindi and Telugu text runs longer than English. Render each child-facing
/// screen in every language on a small phone; any overflow fails the test.
void main() {
  final screens = <String, Widget>{
    'onboarding': const OnboardingScreen(),
    'world map': const WorldMapScreen(),
    'reward': const RewardScreen(
        episodeId: 'pf_ep01',
        badges: ['pattern_spotter', 'ai_friend', 'data_collector']),
  };

  for (final lang in kLanguages) {
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('[$lang] $name fits a 360x640 phone', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            hiveStorageServiceProvider.overrideWithValue(FakeStorage(
                profile: ChildProfile(
                    id: 'c',
                    nickname: 'E',
                    language: lang,
                    createdAt: DateTime(2026)))),
          ],
          child: MaterialApp(home: screen),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (name == 'world map') {
          expect(find.text(AppStrings.of(lang).chooseWorld), findsOneWidget);
        }
      });
    }
  }
}

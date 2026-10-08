import 'package:ai_explorer/core/audio/audio_service.dart';
import 'package:ai_explorer/core/rive/aiko_widget.dart';
import 'package:ai_explorer/core/purchases/purchase_service.dart';
import 'package:ai_explorer/core/security/monotonic_clock.dart';
import 'package:ai_explorer/core/speech/speech_service.dart';
import 'package:ai_explorer/core/storage/models/child_profile.dart';
import 'package:ai_explorer/core/storage/models/subscription_state.dart';
import 'package:ai_explorer/features/episode_player/episode_player_screen.dart';
import 'package:ai_explorer/features/parent_dashboard/parent_dashboard_screen.dart';
import 'package:ai_explorer/features/parent_dashboard/pin_gate_screen.dart';
import 'package:ai_explorer/curriculum/episode_catalog.dart';
import 'package:ai_explorer/curriculum/episode_controller.dart';
import 'package:ai_explorer/features/onboarding/onboarding_screen.dart';
import 'package:ai_explorer/features/reward/reward_screen.dart';
import 'package:ai_explorer/features/world_map/world_map_screen.dart';
import 'package:ai_explorer/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_clock.dart';
import 'support/fake_storage.dart';
import 'support/fake_store.dart';

class _Audio extends Fake implements AudioService {
  @override
  Future<void> play(String lineId, {String lang = 'en'}) async {}
}

class _Speech extends Fake implements SpeechService {
  @override
  void dispose() {}
}

/// Hindi and Telugu text runs longer than English. Render each child-facing
/// screen in every language on a small phone; any overflow fails the test.
void main() {
  final screens = <String, Widget>{
    'onboarding': const OnboardingScreen(),
    'world map': const WorldMapScreen(),
    'reward': const RewardScreen(
        episodeId: 'pf_ep01',
        badges: ['pattern_spotter', 'ai_friend', 'data_collector']),
    // pf_ep01 stops at its tap step; ml_ep01 at its 6-item rhythm game
    'episode pf_ep01': const EpisodePlayerScreen(episodeId: 'pf_ep01'),
    'episode ml_ep01': const EpisodePlayerScreen(episodeId: 'ml_ep01'),
    'PIN gate': const PinGateScreen(),
    'parent dashboard': const ParentDashboardScreen(),
  };

  for (final lang in kLanguages) {
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('[$lang] $name fits a 360x640 phone', (tester) async {
        // rootBundle caches loads as futures from the previous test's zone,
        // which never complete in this one; start each test clean.
        rootBundle.clear();
        AikoWidget.resetRiveCache();
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            hiveStorageServiceProvider.overrideWithValue(FakeStorage(
                sub: const SubscriptionState(isPremium: true),
                profile: ChildProfile(
                    id: 'c',
                    nickname: 'E',
                    language: lang,
                    createdAt: DateTime(2026)))),
            audioServiceProvider.overrideWithValue(_Audio()),
            speechServiceProvider.overrideWithValue(_Speech()),
            monotonicClockProvider.overrideWithValue(FakeClock()),
            storeClientProvider.overrideWithValue(FakeStore()),
          ],
          child: MaterialApp(home: screen),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (name.startsWith('PIN')) {
          // Stop the gate's 15 s lock-check timer before the test ends.
          await tester.pumpWidget(const SizedBox());
        }
        if (name == 'world map') {
          expect(find.text(AppStrings.of(lang).chooseWorld), findsOneWidget);
        }
      });
    }
  }
}

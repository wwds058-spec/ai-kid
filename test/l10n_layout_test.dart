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
import 'dart:io';

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

  // 360x640 phone, plus tablets in both orientations: Android 16 ignores the
  // portrait lock on large screens for apps targeting API 36.
  const sizes = {
    '360x640 phone': Size(360, 640),
    '1280x800 tablet (landscape)': Size(1280, 800),
    '800x1280 tablet (portrait)': Size(800, 1280),
  };
  for (final MapEntry(key: sizeName, value: size) in sizes.entries)
  for (final lang in kLanguages) {
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('[$lang] $name fits a $sizeName', (tester) async {
        // rootBundle caches loads as futures from the previous test's zone,
        // which never complete in this one; start each test clean.
        rootBundle.clear();
        AikoWidget.resetRiveCache();
        // Collect every framework error. The only one allowed is the loud
        // "aiko.riv missing" report (character not delivered yet); any
        // overflow or other error fails the test.
        final errors = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = previous);
        tester.view.physicalSize = size;
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
        FlutterError.onError = previous;
        expect(tester.takeException(), isNull);
        final unexpected = errors
            .where((e) =>
                !(e.library == 'aiko_widget' &&
                    '${e.context}'.contains('emoji fallback') &&
                    !File(AikoWidget.kAsset).existsSync()))
            .map((e) => e.exceptionAsString());
        expect(unexpected, isEmpty);
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

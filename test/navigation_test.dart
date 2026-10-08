import 'package:ai_explorer/app/router.dart';
import 'package:ai_explorer/core/purchases/subscription_provider.dart';
import 'package:ai_explorer/core/storage/models/child_profile.dart';
import 'package:ai_explorer/core/storage/models/episode_progress.dart';
import 'package:ai_explorer/core/storage/models/subscription_state.dart';
import 'package:ai_explorer/curriculum/episode_catalog.dart';
import 'package:ai_explorer/curriculum/episode_controller.dart';
import 'package:ai_explorer/features/onboarding/onboarding_screen.dart';
import 'package:ai_explorer/features/world_map/world_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_storage.dart';

/// A world whose only episode needs Premium, to exercise the locked state
/// (the shipped catalog has no premium episodes yet).
const _premiumWorld = CatalogWorld(
  id: 'music_lab',
  prefix: 'ml',
  emoji: '🎵',
  color: 0xFF7C3AED,
  episodes: [CatalogEpisode('ml_ep01', premium: true)],
);

late ProviderContainer _container;

Widget _app(Widget home, {FakeStorage? storage, List<CatalogWorld>? worlds}) {
  _container = ProviderContainer(overrides: [
    hiveStorageServiceProvider.overrideWithValue(storage ?? FakeStorage()),
    if (worlds != null) catalogWorldsProvider.overrideWithValue(worlds),
  ]);
  addTearDown(_container.dispose);
  return UncontrolledProviderScope(
    container: _container,
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/start',
        routes: [
          GoRoute(path: '/start', builder: (_, __) => home),
          GoRoute(
              path: Routes.pinGate,
              builder: (_, __) => const Scaffold(body: Text('PIN GATE'))),
          GoRoute(
              path: Routes.parentDashboard,
              builder: (_, __) => const Scaffold(body: Text('DASHBOARD'))),
          GoRoute(
              path: Routes.worldMap,
              builder: (_, __) => const Scaffold(body: Text('WORLD MAP'))),
          GoRoute(
              path: Routes.episode,
              builder: (_, s) => Scaffold(
                  body: Text('EPISODE ${s.pathParameters['episodeId']}'))),
        ],
      ),
    ),
  );
}

void main() {
  group('parent area is entered through the PIN gate', () {
    testWidgets('from onboarding', (tester) async {
      await tester.pumpWidget(_app(const OnboardingScreen()));
      await tester.tap(find.text('Parent / Settings'));
      await tester.pumpAndSettle();
      expect(find.text('PIN GATE'), findsOneWidget);
    });

    testWidgets('from the world map', (tester) async {
      await tester.pumpWidget(_app(const WorldMapScreen()));
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      expect(find.text('PIN GATE'), findsOneWidget);
    });
  });

  testWidgets('Pattern Forest opens the first unfinished episode',
      (tester) async {
    await tester.pumpWidget(_app(const WorldMapScreen(),
        storage: FakeStorage(progress: {
          'pf_ep01': EpisodeProgress(
              episodeId: 'pf_ep01', completed: true, lastPlayedAt: DateTime(2026)),
        })));
    await tester.tap(find.text('Pattern Forest'));
    await tester.pumpAndSettle();
    expect(find.text('EPISODE pf_ep02'), findsOneWidget);
  });

  testWidgets('worlds without episodes show "Coming soon" and do nothing',
      (tester) async {
    await tester.pumpWidget(_app(const WorldMapScreen()));
    expect(find.text('🌱 Coming soon'), findsNWidgets(2));
    expect(find.text('🔒 Premium'), findsNothing);
    await tester.tap(find.text('Music Lab'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('EPISODE'), findsNothing);
  });

  testWidgets('all-premium world is locked and asks for a grown-up',
      (tester) async {
    await tester.pumpWidget(
        _app(const WorldMapScreen(), worlds: const [_premiumWorld]));
    expect(find.text('🔒 Premium'), findsOneWidget);
    await tester.tap(find.text('Music Lab'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ask a grown-up'), findsOneWidget);
    await tester.tap(find.text("I'm a grown-up"));
    await tester.pumpAndSettle();
    expect(find.text('PIN GATE'), findsOneWidget);
  });

  testWidgets('a purchase unlocks the world without a restart', (tester) async {
    final storage = FakeStorage();
    await tester.pumpWidget(_app(const WorldMapScreen(),
        storage: storage, worlds: const [_premiumWorld]));
    expect(find.text('🔒 Premium'), findsOneWidget);

    // What the dashboard does after PurchaseService saves the entitlement
    await storage.saveSubscription(const SubscriptionState(isPremium: true));
    _container.read(subscriptionProvider.notifier).refresh();
    await tester.pumpAndSettle();

    expect(find.text('🔒 Premium'), findsNothing);
    await tester.tap(find.text('Music Lab'));
    await tester.pumpAndSettle();
    expect(find.text('EPISODE ml_ep01'), findsOneWidget);
  });

  testWidgets('expired subscription stays unlocked during the 3-day grace',
      (tester) async {
    await tester.pumpWidget(_app(const WorldMapScreen(),
        worlds: const [_premiumWorld],
        storage: FakeStorage(
            sub: SubscriptionState(
                isPremium: true,
                expiresAt: DateTime.now().subtract(const Duration(days: 1))))));
    expect(find.text('🔒 Premium'), findsNothing);
  });

  group('language', () {
    testWidgets('onboarding picker switches the text and saves the profile',
        (tester) async {
      final storage = FakeStorage();
      await tester.pumpWidget(_app(const OnboardingScreen(), storage: storage));
      expect(find.text("Let's Go! 🚀"), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('lang_hi')));
      await tester.pumpAndSettle();
      expect(find.text('चलो चलें! 🚀'), findsOneWidget);
      expect(storage.profile?.language, 'hi');

      await tester.tap(find.byKey(const ValueKey('lang_te')));
      await tester.pumpAndSettle();
      expect(find.text('వెళ్దాం! 🚀'), findsOneWidget);
      expect(storage.profile?.language, 'te');
    });

    testWidgets('world map uses the saved language', (tester) async {
      await tester.pumpWidget(_app(const WorldMapScreen(),
          storage: FakeStorage(
              profile: ChildProfile(
                  id: 'c1',
                  nickname: 'Explorer',
                  language: 'te',
                  createdAt: DateTime(2026)))));
      expect(find.text('ఒక ప్రపంచాన్ని ఎంచుకో'), findsOneWidget);
      expect(find.text('ప్యాటర్న్ అడవి'), findsOneWidget);
    });
  });
}

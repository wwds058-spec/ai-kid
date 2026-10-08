import 'package:ai_explorer/app/router.dart';
import 'package:ai_explorer/core/storage/hive_storage_service.dart';
import 'package:ai_explorer/core/storage/models/episode_progress.dart';
import 'package:ai_explorer/curriculum/episode_controller.dart';
import 'package:ai_explorer/features/onboarding/onboarding_screen.dart';
import 'package:ai_explorer/features/world_map/world_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeStorage extends Fake implements HiveStorageService {
  FakeStorage([this.progress = const []]);
  final List<EpisodeProgress> progress;
  @override
  List<EpisodeProgress> allProgress() => progress;
}

Widget _app(Widget home, {FakeStorage? storage}) => ProviderScope(
    overrides: [
      hiveStorageServiceProvider.overrideWithValue(storage ?? FakeStorage()),
    ],
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
              path: Routes.episode,
              builder: (_, s) =>
                  Scaffold(body: Text('EPISODE ${s.pathParameters['episodeId']}'))),
        ],
      ),
    ));

void main() {
  testWidgets('onboarding "Parent / Settings" goes to the PIN gate',
      (tester) async {
    await tester.pumpWidget(_app(const OnboardingScreen()));
    await tester.tap(find.text('Parent / Settings'));
    await tester.pumpAndSettle();
    expect(find.text('PIN GATE'), findsOneWidget);
    expect(find.text('DASHBOARD'), findsNothing);
  });

  testWidgets('world map person icon goes to the PIN gate', (tester) async {
    await tester.pumpWidget(_app(const WorldMapScreen()));
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(find.text('PIN GATE'), findsOneWidget);
    expect(find.text('DASHBOARD'), findsNothing);
  });

  testWidgets('Pattern Forest opens the first unfinished episode',
      (tester) async {
    await tester.pumpWidget(_app(const WorldMapScreen(),
        storage: FakeStorage([
          EpisodeProgress(
              episodeId: 'pf_ep01',
              completed: true,
              lastPlayedAt: DateTime(2026)),
        ])));
    await tester.tap(find.text('Pattern Forest'));
    await tester.pumpAndSettle();
    expect(find.text('EPISODE pf_ep02'), findsOneWidget);
  });
}

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/security/parent_gate.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/world_map/world_map_screen.dart';
import '../features/episode_player/episode_player_screen.dart';
import '../features/reward/reward_screen.dart';
import '../features/parent_dashboard/pin_gate_screen.dart';
import '../features/parent_dashboard/parent_dashboard_screen.dart';

part 'router.g.dart';

/// Route names — use these constants to navigate, not raw strings.
abstract class Routes {
  static const onboarding      = '/onboarding';
  static const worldMap        = '/worlds';
  static const episode         = '/episode/:episodeId';
  static const reward          = '/reward/:episodeId';
  /// Entry point for the parent area — always goes through PIN gate first.
  static const pinGate         = '/parent';
  /// Only navigated to after PIN is verified.
  static const parentDashboard = '/parent-dashboard';

  static String episodePath(String id)  => '/episode/$id';
  static String rewardPath(String id)   => '/reward/$id';
}

// Lives for the whole app: it owns long-lived state (router / player /
// recogniser) and is only read, not watched, by its users.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: Routes.onboarding,
    debugLogDiagnostics: true,
    // The dashboard is only reachable right after a successful PIN check.
    redirect: (context, state) =>
        state.matchedLocation == Routes.parentDashboard &&
                !ref.read(parentGateProvider).isUnlocked
            ? Routes.pinGate
            : null,
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.worldMap,
        builder: (_, __) => const WorldMapScreen(),
      ),
      GoRoute(
        path: Routes.episode,
        builder: (context, state) {
          final episodeId = state.pathParameters['episodeId']!;
          return EpisodePlayerScreen(episodeId: episodeId);
        },
      ),
      GoRoute(
        path: Routes.reward,
        builder: (context, state) {
          final episodeId = state.pathParameters['episodeId']!;
          final badges = (state.extra as List<String>?) ?? [];
          return RewardScreen(episodeId: episodeId, badges: badges);
        },
      ),
      // PIN gate — always shown when entering the parent area
      GoRoute(
        path: Routes.pinGate,
        builder: (_, __) => const PinGateScreen(),
      ),
      // Parent dashboard — only reachable after PIN is verified
      GoRoute(
        path: Routes.parentDashboard,
        builder: (_, __) => const ParentDashboardScreen(),
      ),
    ],
  );
}

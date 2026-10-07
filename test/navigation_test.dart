import 'package:ai_explorer/app/router.dart';
import 'package:ai_explorer/features/onboarding/onboarding_screen.dart';
import 'package:ai_explorer/features/world_map/world_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The parent area must always be entered through the PIN gate.
Widget _app(Widget home) => MaterialApp.router(
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
        ],
      ),
    );

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
}

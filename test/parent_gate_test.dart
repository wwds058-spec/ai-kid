import 'package:ai_explorer/app/router.dart';
import 'package:ai_explorer/core/security/parent_gate.dart';
import 'package:ai_explorer/core/security/pin_service.dart';
import 'package:ai_explorer/core/storage/models/parent_settings.dart';
import 'package:ai_explorer/curriculum/episode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_storage.dart';

void main() {
  group('ParentGate', () {
    test('starts locked, unlocks, expires after ttl, and re-locks', () {
      var now = DateTime(2026, 1, 1, 12);
      final gate = ParentGate(ttl: const Duration(minutes: 5), now: () => now);
      expect(gate.isUnlocked, isFalse);
      gate.unlock();
      expect(gate.isUnlocked, isTrue);
      now = now.add(const Duration(minutes: 4, seconds: 59));
      expect(gate.isUnlocked, isTrue);
      now = now.add(const Duration(seconds: 1));
      expect(gate.isUnlocked, isFalse);
      gate.unlock();
      gate.lock();
      expect(gate.isUnlocked, isFalse);
    });
  });

  group('router guard', () {
    late ProviderContainer container;
    late GoRouter router;

    Future<void> pump(WidgetTester tester) async {
      container = ProviderContainer(overrides: [
        hiveStorageServiceProvider.overrideWithValue(
            FakeStorage(settings: ParentSettings(pinHash: PinService.hash('1234')))),
      ]);
      addTearDown(container.dispose);
      router = container.read(appRouterProvider);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ));
    }

    String location() =>
        router.routerDelegate.currentConfiguration.uri.toString();

    testWidgets('direct navigation to the dashboard lands on the PIN gate',
        (tester) async {
      await pump(tester);
      router.go(Routes.parentDashboard);
      await tester.pumpAndSettle();
      expect(location(), Routes.pinGate);
      expect(find.text('Parent Dashboard'), findsNothing);
    });

    testWidgets('correct PIN opens the dashboard; leaving re-locks it',
        (tester) async {
      await pump(tester);
      router.go(Routes.pinGate);
      await tester.pumpAndSettle();
      for (final d in ['1', '2', '3', '4']) {
        await tester.tap(find.text(d).last);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(location(), Routes.parentDashboard);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(container.read(parentGateProvider).isUnlocked, isFalse);
      router.go(Routes.parentDashboard);
      await tester.pumpAndSettle();
      expect(location(), Routes.pinGate);
    });

    Future<void> enter(WidgetTester tester, String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.text(d).last);
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    testWidgets('3 wrong PINs lock the gate, and leaving does not reset it',
        (tester) async {
      await pump(tester);
      router.go(Routes.pinGate);
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await enter(tester, '9999');
      }
      expect(find.text('Too many wrong attempts.'), findsOneWidget);

      router.go(Routes.worldMap);
      await tester.pumpAndSettle();
      router.go(Routes.pinGate);
      await tester.pumpAndSettle();
      expect(find.text('Too many wrong attempts.'), findsOneWidget);
      expect(find.text('1'), findsNothing, reason: 'keypad hidden while locked');
    });

    testWidgets('wrong PIN stays on the gate', (tester) async {
      await pump(tester);
      router.go(Routes.pinGate);
      await tester.pumpAndSettle();
      for (final d in ['9', '9', '9', '9']) {
        await tester.tap(find.text(d).last);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(location(), Routes.pinGate);
      expect(container.read(parentGateProvider).isUnlocked, isFalse);
    });
  });
}

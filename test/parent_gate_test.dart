import 'dart:math';

import 'package:ai_explorer/app/router.dart';
import 'package:ai_explorer/core/security/grown_up_check.dart';
import 'package:ai_explorer/core/security/monotonic_clock.dart';
import 'package:ai_explorer/core/security/parent_gate.dart';
import 'package:ai_explorer/core/security/pin_service.dart';
import 'package:ai_explorer/core/storage/models/parent_settings.dart';
import 'package:ai_explorer/curriculum/episode_controller.dart';
import 'package:ai_explorer/l10n/parent_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_clock.dart';
import 'support/fake_storage.dart';

const _p = ParentStrings.en;

void main() {
  group('ParentGate', () {
    test('starts locked, unlocks, expires after ttl, and re-locks', () {
      var now = const Duration(hours: 1);
      final gate =
          ParentGate(ttl: const Duration(minutes: 5), elapsed: () => now);
      expect(gate.isUnlocked, isFalse);
      gate.unlock();
      expect(gate.isUnlocked, isTrue);
      now += const Duration(minutes: 4, seconds: 59);
      expect(gate.isUnlocked, isTrue);
      now += const Duration(seconds: 1);
      expect(gate.isUnlocked, isFalse);
      gate.unlock();
      gate.lock();
      expect(gate.isUnlocked, isFalse);
    });
  });

  late ProviderContainer container;
  late GoRouter router;
  late FakeStorage storage;
  late FakeClock clock;

  Future<void> pump(WidgetTester tester, {String? pin = '1234'}) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    storage = FakeStorage(
        settings: ParentSettings(pinHash: pin == null ? null : PinService.hash(pin)));
    clock = FakeClock();
    container = ProviderContainer(overrides: [
      hiveStorageServiceProvider.overrideWithValue(storage),
      monotonicClockProvider.overrideWithValue(clock),
      grownUpRandomProvider.overrideWithValue(Random(42)),
    ]);
    addTearDown(container.dispose);
    router = container.read(appRouterProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
  }

  String location() => router.routerDelegate.currentConfiguration.uri.toString();

  Future<void> enter(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> openGate(WidgetTester tester) async {
    router.go(Routes.pinGate);
    await tester.pumpAndSettle();
  }

  group('router guard', () {
    testWidgets('direct navigation to the dashboard lands on the PIN gate',
        (tester) async {
      await pump(tester);
      router.go(Routes.parentDashboard);
      await tester.pumpAndSettle();
      expect(location(), Routes.pinGate);
      expect(find.text(_p.dashboardTitle), findsNothing);
    });

    testWidgets('correct PIN opens the dashboard; leaving re-locks it',
        (tester) async {
      await pump(tester);
      await openGate(tester);
      await enter(tester, '1234');
      expect(location(), Routes.parentDashboard);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(container.read(parentGateProvider).isUnlocked, isFalse);
      router.go(Routes.parentDashboard);
      await tester.pumpAndSettle();
      expect(location(), Routes.pinGate);
    });

    testWidgets('wrong PIN stays on the gate', (tester) async {
      await pump(tester);
      await openGate(tester);
      await enter(tester, '9999');
      expect(location(), Routes.pinGate);
      expect(find.text(_p.wrongPin(2)), findsOneWidget);
    });
  });

  group('regression: lockout survives leaving, restarting and clock changes',
      () {
    testWidgets('3 wrong PINs lock; leaving and returning stays locked',
        (tester) async {
      await pump(tester);
      await openGate(tester);
      for (var i = 0; i < 3; i++) {
        await enter(tester, '9999');
      }
      expect(find.text(_p.tooManyAttempts), findsOneWidget);
      router.go(Routes.worldMap);
      await tester.pumpAndSettle();
      await openGate(tester);
      expect(find.text(_p.tooManyAttempts), findsOneWidget);
      expect(find.text('1'), findsNothing, reason: 'keypad hidden while locked');
    });

    testWidgets('lock lifts only after real elapsed time, even across reboot',
        (tester) async {
      await pump(tester);
      await openGate(tester);
      for (var i = 0; i < 3; i++) {
        await enter(tester, '9999');
      }
      // Changing the wall clock is irrelevant: the gate never reads it.
      // A reboot restarts the monotonic clock; the lock must hold.
      clock.reboot();
      router.go(Routes.worldMap);
      await tester.pumpAndSettle();
      await openGate(tester);
      expect(find.text(_p.tooManyAttempts), findsOneWidget);

      clock.advance(const Duration(minutes: 5));
      router.go(Routes.worldMap);
      await tester.pumpAndSettle();
      await openGate(tester);
      expect(find.text(_p.enterPin), findsOneWidget);
      await enter(tester, '1234');
      expect(location(), Routes.parentDashboard);
    });
  });

  group('regression: first PIN needs a grown-up', () {
    String answer() => GrownUpCheck.random(Random(42)).answer;

    testWidgets('fresh install shows the grown-up check, not PIN creation',
        (tester) async {
      await pump(tester, pin: null);
      await openGate(tester);
      expect(find.text(_p.grownUpCheckTitle), findsOneWidget);
      expect(find.text(_p.createPin), findsNothing);
      expect(find.byKey(const ValueKey('grown_up_prompt')), findsOneWidget);
    });

    testWidgets('passing the check, then create + confirm, sets the PIN',
        (tester) async {
      await pump(tester, pin: null);
      await openGate(tester);
      await enter(tester, answer());
      expect(find.text(_p.createPin), findsOneWidget);
      await enter(tester, '2580');
      expect(find.text(_p.confirmPin), findsOneWidget);
      await enter(tester, '2580');
      expect(location(), Routes.parentDashboard);
      expect(PinService.verify('2580', storage.settings.pinHash!), isTrue);
    });

    testWidgets('a child mashing keys cannot create a PIN', (tester) async {
      await pump(tester, pin: null);
      await openGate(tester);
      await enter(tester, '1111');
      expect(find.text(_p.grownUpCheckWrong), findsOneWidget);
      expect(find.text(_p.createPin), findsNothing);
      expect(storage.settings.pinHash, isNull);
    });

    testWidgets('3 wrong grown-up checks lock the gate', (tester) async {
      await pump(tester, pin: null);
      await openGate(tester);
      for (var i = 0; i < 3; i++) {
        await enter(tester, '1111');
      }
      expect(find.text(_p.tooManyAttempts), findsOneWidget);
      expect(storage.settings.pinHash, isNull);
    });

    testWidgets('a new check is shown after a wrong answer', (tester) async {
      await pump(tester, pin: null);
      await openGate(tester);
      final first = tester
          .widget<Text>(find.byKey(const ValueKey('grown_up_prompt')))
          .data;
      await enter(tester, '1111');
      final second = tester
          .widget<Text>(find.byKey(const ValueKey('grown_up_prompt')))
          .data;
      expect(second, isNot(first));
    });

    testWidgets('mismatched confirmation goes back to create, PIN not saved',
        (tester) async {
      await pump(tester, pin: null);
      await openGate(tester);
      await enter(tester, answer());
      await enter(tester, '2580');
      await enter(tester, '0852');
      expect(find.text(_p.createPin), findsOneWidget);
      expect(storage.settings.pinHash, isNull);
    });
  });
}

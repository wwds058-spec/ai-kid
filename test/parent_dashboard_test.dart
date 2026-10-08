import 'package:ai_explorer/core/purchases/purchase_service.dart';
import 'package:ai_explorer/core/purchases/store_client.dart';
import 'package:ai_explorer/core/purchases/subscription_provider.dart';
import 'package:ai_explorer/core/storage/models/parent_settings.dart';
import 'package:ai_explorer/core/storage/models/subscription_state.dart';
import 'package:ai_explorer/curriculum/episode_controller.dart';
import 'package:ai_explorer/features/parent_dashboard/parent_dashboard_screen.dart';
import 'package:ai_explorer/l10n/language.dart';
import 'package:ai_explorer/l10n/parent_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_storage.dart';
import 'support/fake_store.dart';

/// Real PurchaseService + SubscriptionNotifier, fake store.
void main() {
  late ProviderContainer container;
  late FakeStore store;
  const p = ParentStrings.en;

  Future<FakeStorage> pump(WidgetTester tester,
      {FakeStorage? storage, String apiKey = 'goog_test'}) async {
    tester.view.physicalSize = const Size(420, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final s = storage ?? FakeStorage();
    store = FakeStore();
    container = ProviderContainer(overrides: [
      hiveStorageServiceProvider.overrideWithValue(s),
      storeClientProvider.overrideWithValue(store),
    ]);
    addTearDown(container.dispose);
    await container.read(purchaseServiceProvider).init(apiKey);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ParentDashboardScreen()),
    ));
    return s;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('successful purchase says so and unlocks app-wide',
      (tester) async {
    await pump(tester);
    expect(find.text(p.statusFree), findsOneWidget);
    await tapText(tester, p.upgrade);
    expect(find.text(p.purchaseUnlocked), findsOneWidget);
    expect(find.text(p.statusPremium), findsOneWidget);
    expect(find.text(p.upgrade), findsNothing);
    expect(container.read(isPremiumProvider), isTrue);
  });

  for (final (kind, message) in [
    (StoreErrorKind.cancelled, p.purchaseCancelled),
    (StoreErrorKind.unavailable, p.purchaseUnavailable),
    (StoreErrorKind.failed, p.purchaseFailed),
  ]) {
    testWidgets('${kind.name}: explains and stays free', (tester) async {
      await pump(tester);
      store.failBuy = StoreException(kind);
      await tapText(tester, p.upgrade);
      expect(find.text(message), findsOneWidget);
      expect(find.text(p.statusFree), findsOneWidget);
      expect(container.read(isPremiumProvider), isFalse);
    });
  }

  testWidgets('restore that finds a purchase unlocks', (tester) async {
    await pump(tester);
    store.current = FakeStore.premiumSnapshot;
    await tapText(tester, p.restore);
    expect(find.text(p.restoreFound), findsOneWidget);
    expect(container.read(isPremiumProvider), isTrue);
  });

  testWidgets('build without an API key says purchases are unavailable',
      (tester) async {
    await pump(tester, apiKey: '');
    expect(find.text(p.storeNotConfigured), findsOneWidget);
    await tapText(tester, p.upgrade);
    expect(find.text(p.purchaseUnavailable), findsOneWidget);
  });

  group('status line', () {
    final now = DateTime.now();
    SubscriptionState s(
            {bool premium = true,
            int days = 30,
            bool renew = true,
            bool billing = false}) =>
        SubscriptionState(
            isPremium: premium,
            expiresAt: now.add(Duration(days: days)),
            willRenew: renew,
            billingIssue: billing);
    // isActiveWithGrace reads the real clock, so dates are relative to now.
    String status(SubscriptionState sub) =>
        ParentDashboardScreenStatus.text(sub, p, now);

    test('free / premium / cancelled / billing issue / offline grace', () {
      expect(status(const SubscriptionState()), p.statusFree);
      expect(status(s()), p.statusPremium);
      expect(status(s(renew: false)), p.statusCancelled);
      expect(status(s(billing: true)), p.statusBillingIssue);
      expect(status(s(days: -1)), p.statusGrace);
    });
  });

  testWidgets('cancelled subscription shows "Premium until" and no upsell',
      (tester) async {
    await pump(tester,
        storage: FakeStorage(
            sub: SubscriptionState(
                isPremium: true,
                willRenew: false,
                expiresAt: DateTime.now().add(const Duration(days: 10)))));
    expect(find.text(p.statusCancelled), findsOneWidget);
    expect(find.textContaining('Premium until'), findsOneWidget);
    expect(find.text(p.upgrade), findsNothing);
  });

  testWidgets('offline grace is shown and offers renewal', (tester) async {
    await pump(tester,
        storage: FakeStorage(
            sub: SubscriptionState(
                isPremium: true,
                expiresAt: DateTime.now().subtract(const Duration(days: 1)))));
    expect(find.text(p.statusGrace), findsOneWidget);
    expect(find.text(p.renew), findsOneWidget);
  });

  testWidgets('language setting saves to the profile', (tester) async {
    final storage = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('language_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('తెలుగు').last);
    await tester.pumpAndSettle();
    expect(storage.profile?.language, 'te');
    expect(container.read(languageProvider), 'te');
  });

  testWidgets('voice switch is saved', (tester) async {
    final storage = await pump(tester,
        storage: FakeStorage(settings: const ParentSettings()));
    await tester.tap(find.byKey(const ValueKey('voice_switch')));
    await tester.pumpAndSettle();
    expect(storage.settings.voiceEnabled, isFalse);
  });

  testWidgets('no dead controls: AI toggle and daily limit are gone',
      (tester) async {
    await pump(tester);
    expect(find.textContaining('AI interaction'), findsNothing);
    expect(find.textContaining('Daily limit'), findsNothing);
  });
}

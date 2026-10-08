import 'package:ai_explorer/core/purchases/purchase_service.dart';
import 'package:ai_explorer/core/purchases/store_client.dart';
import 'package:ai_explorer/core/purchases/subscription_provider.dart';
import 'package:ai_explorer/core/storage/models/subscription_state.dart';
import 'package:ai_explorer/curriculum/episode_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_storage.dart';
import 'support/fake_store.dart';

void main() {
  late FakeStore store;
  late FakeStorage storage;
  late ProviderContainer c;

  PurchaseService svc() => c.read(purchaseServiceProvider);
  bool premium() => c.read(isPremiumProvider);

  Future<void> boot(
      {String key = 'goog_test',
      SubscriptionState? cached,
      bool offlineAtLaunch = false}) async {
    store = FakeStore();
    if (offlineAtLaunch) {
      store.failFetch = const StoreException(StoreErrorKind.unavailable);
    }
    storage = FakeStorage(sub: cached ?? const SubscriptionState());
    c = ProviderContainer(overrides: [
      hiveStorageServiceProvider.overrideWithValue(storage),
      storeClientProvider.overrideWithValue(store),
    ]);
    addTearDown(c.dispose);
    await c.read(subscriptionProvider.notifier).start(key);
  }

  group('configuration', () {
    test('no API key: purchases unavailable, nothing crashes, free stays free',
        () async {
      await boot(key: '');
      expect(svc().isConfigured, isFalse);
      expect(store.configuredWith, isNull);
      expect(await svc().buyAnnual(), PurchaseResult.unavailable);
      expect(await svc().restorePurchases(), RestoreResult.unavailable);
      expect(await svc().sync(), SyncResult.notConfigured);
      expect(premium(), isFalse);
    });

    test('store configure failure leaves purchases unavailable', () async {
      store = FakeStore()..failConfigure = const StoreException(StoreErrorKind.failed);
      storage = FakeStorage();
      c = ProviderContainer(overrides: [
        hiveStorageServiceProvider.overrideWithValue(storage),
        storeClientProvider.overrideWithValue(store),
      ]);
      addTearDown(c.dispose);
      await c.read(subscriptionProvider.notifier).start('goog_test');
      expect(svc().isConfigured, isFalse);
      expect(await svc().buyAnnual(), PurchaseResult.unavailable);
    });

    test('launch verifies the entitlement with the store', () async {
      await boot();
      expect(store.configuredWith, 'goog_test');
      expect(store.fetches, 1);
      expect(storage.sub.lastVerifiedAt, isNotNull);
    });
  });

  group('purchase', () {
    test('success unlocks and caches the entitlement', () async {
      await boot();
      expect(await svc().buyAnnual(), PurchaseResult.unlocked);
      c.read(subscriptionProvider.notifier).refresh();
      expect(premium(), isTrue);
      expect(storage.sub.productId, 'ai_explorer_annual');
    });

    for (final (kind, result) in [
      (StoreErrorKind.cancelled, PurchaseResult.cancelled),
      (StoreErrorKind.unavailable, PurchaseResult.unavailable),
      (StoreErrorKind.failed, PurchaseResult.failed),
    ]) {
      test('${kind.name} → ${result.name}, stays free', () async {
        await boot();
        store.failBuy = StoreException(kind);
        expect(await svc().buyAnnual(), result);
        c.read(subscriptionProvider.notifier).refresh();
        expect(premium(), isFalse);
      });
    }

    test('paid but no entitlement → notEntitled, stays free', () async {
      await boot();
      store.purchaseResult = const EntitlementSnapshot.inactive();
      expect(await svc().buyAnnual(), PurchaseResult.notEntitled);
      c.read(subscriptionProvider.notifier).refresh();
      expect(premium(), isFalse);
    });
  });

  group('restore', () {
    test('finds an existing purchase (e.g. reinstall)', () async {
      await boot();
      store.current = FakeStore.premiumSnapshot;
      expect(await svc().restorePurchases(), RestoreResult.found);
      c.read(subscriptionProvider.notifier).refresh();
      expect(premium(), isTrue);
    });

    test('nothing to restore', () async {
      await boot();
      expect(await svc().restorePurchases(), RestoreResult.nothingFound);
    });

    test('store unreachable keeps the cache', () async {
      await boot(
          offlineAtLaunch: true,
          cached: SubscriptionState(
              isPremium: true,
              expiresAt: DateTime.now().add(const Duration(days: 30))));
      store.failRestore = const StoreException(StoreErrorKind.unavailable);
      expect(await svc().restorePurchases(), RestoreResult.unavailable);
      expect(premium(), isTrue);
    });
  });

  group('entitlement refresh', () {
    test('subscription expired in the store locks on next sync', () async {
      await boot();
      await svc().buyAnnual();
      c.read(subscriptionProvider.notifier).refresh();
      expect(premium(), isTrue);

      store.current = const EntitlementSnapshot.inactive(); // expired
      expect(await c.read(subscriptionProvider.notifier).sync(), SyncResult.verified);
      expect(premium(), isFalse);
    });

    test('refund/revocation pushed by the store locks immediately', () async {
      await boot();
      await svc().buyAnnual();
      c.read(subscriptionProvider.notifier).refresh();
      store.push(const EntitlementSnapshot.inactive());
      await Future<void>.delayed(Duration.zero);
      expect(premium(), isFalse);
    });

    test('renewal pushed by the store extends Premium', () async {
      await boot();
      final later = DateTime.now().add(const Duration(days: 730));
      store.push(EntitlementSnapshot(active: true, expiresAt: later));
      await Future<void>.delayed(Duration.zero);
      expect(premium(), isTrue);
      expect(c.read(subscriptionProvider).expiresAt, later);
    });

    test('cancelled but paid up: Premium until expiry, marked not renewing',
        () async {
      await boot();
      store.current = EntitlementSnapshot(
          active: true,
          expiresAt: DateTime.now().add(const Duration(days: 10)),
          willRenew: false);
      await c.read(subscriptionProvider.notifier).sync();
      expect(premium(), isTrue);
      expect(c.read(subscriptionProvider).willRenew, isFalse);
    });

    test('Play billing grace (payment problem) stays Premium, flagged', () async {
      await boot();
      store.current = EntitlementSnapshot(
          active: true,
          expiresAt: DateTime.now().add(const Duration(days: 3)),
          billingIssue: true);
      await c.read(subscriptionProvider.notifier).sync();
      expect(premium(), isTrue);
      expect(c.read(subscriptionProvider).billingIssue, isTrue);
    });

    test('offline: cached Premium survives until 3 days past expiry', () async {
      await boot(offlineAtLaunch: true, cached: SubscriptionState(
          isPremium: true,
          expiresAt: DateTime.now().subtract(const Duration(days: 2))));
      store.failFetch = const StoreException(StoreErrorKind.unavailable);
      expect(await c.read(subscriptionProvider.notifier).sync(), SyncResult.offline);
      expect(premium(), isTrue, reason: 'within offline grace');
    });

    test('offline: cached Premium locks once past the 3-day grace', () async {
      store = FakeStore()..failFetch = const StoreException(StoreErrorKind.unavailable);
      storage = FakeStorage(
          sub: SubscriptionState(
              isPremium: true,
              expiresAt: DateTime.now().subtract(const Duration(days: 4))));
      c = ProviderContainer(overrides: [
        hiveStorageServiceProvider.overrideWithValue(storage),
        storeClientProvider.overrideWithValue(store),
      ]);
      addTearDown(c.dispose);
      expect(await c.read(subscriptionProvider.notifier).start('goog_test'),
          SyncResult.offline);
      expect(premium(), isFalse);
    });

    test('offline launch with no cache stays free', () async {
      store = FakeStore()..failFetch = const StoreException(StoreErrorKind.unavailable);
      storage = FakeStorage();
      c = ProviderContainer(overrides: [
        hiveStorageServiceProvider.overrideWithValue(storage),
        storeClientProvider.overrideWithValue(store),
      ]);
      addTearDown(c.dispose);
      await c.read(subscriptionProvider.notifier).start('goog_test');
      expect(premium(), isFalse);
    });
  });

  test('stateFrom maps store snapshots exactly', () {
    final now = DateTime(2026, 10, 8);
    final exp = DateTime(2027, 10, 8);
    final on = PurchaseService.stateFrom(
        EntitlementSnapshot(
            active: true, expiresAt: exp, productId: 'p', willRenew: false),
        now);
    expect(on.isPremium, isTrue);
    expect(on.expiresAt, exp);
    expect(on.willRenew, isFalse);
    expect(on.lastVerifiedAt, now);
    final off = PurchaseService.stateFrom(const EntitlementSnapshot.inactive(), now);
    expect(off.isPremium, isFalse);
    expect(off.lastVerifiedAt, now);
  });

  testWidgets('returning to the app re-checks the entitlement', (tester) async {
    await boot();
    await svc().buyAnnual();
    c.read(subscriptionProvider.notifier).refresh();
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const SubscriptionLifecycle(child: SizedBox())));
    final before = store.fetches;

    // Parent cancels/refunds in Google Play while the app is in background
    store.current = const EntitlementSnapshot.inactive();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(store.fetches, before + 1);
    expect(premium(), isFalse);
  });
}

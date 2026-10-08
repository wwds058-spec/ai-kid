import 'package:ai_explorer/core/purchases/purchase_service.dart';
import 'package:ai_explorer/core/purchases/subscription_provider.dart';
import 'package:ai_explorer/core/storage/models/subscription_state.dart';
import 'package:ai_explorer/curriculum/episode_controller.dart';
import 'package:ai_explorer/features/parent_dashboard/parent_dashboard_screen.dart';
import 'package:ai_explorer/l10n/language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_storage.dart';

/// Stands in for RevenueCat: returns [result] and, on success, writes the
/// entitlement to storage the way PurchaseService does.
class FakePurchases extends Fake implements PurchaseService {
  FakePurchases(this.storage, this.result, {this.restoreFinds = false});
  final FakeStorage storage;
  final PurchaseResult result;
  final bool restoreFinds;

  @override
  Future<PurchaseResult> buyAnnual() async {
    if (result == PurchaseResult.unlocked) {
      await storage.saveSubscription(const SubscriptionState(isPremium: true));
    }
    return result;
  }

  @override
  Future<bool> restorePurchases() async {
    if (restoreFinds) {
      await storage.saveSubscription(const SubscriptionState(isPremium: true));
    }
    return restoreFinds;
  }
}

void main() {
  late ProviderContainer container;

  Future<FakeStorage> pump(WidgetTester tester, PurchaseResult result,
      {bool restoreFinds = false, FakeStorage? storage}) async {
    // Phone-height surface so the whole dashboard fits without scrolling
    tester.view.physicalSize = const Size(420, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final s = storage ?? FakeStorage();
    container = ProviderContainer(overrides: [
      hiveStorageServiceProvider.overrideWithValue(s),
      purchaseServiceProvider
          .overrideWithValue(FakePurchases(s, result, restoreFinds: restoreFinds)),
    ]);
    addTearDown(container.dispose);
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
    await pump(tester, PurchaseResult.unlocked);
    expect(find.text('🔓 Free'), findsOneWidget);
    await tapText(tester, 'Upgrade to Premium');
    expect(find.text('✅ Premium unlocked!'), findsOneWidget);
    expect(find.text('✅ Premium'), findsOneWidget);
    expect(find.text('Upgrade to Premium'), findsNothing);
    expect(container.read(isPremiumProvider), isTrue);
  });

  for (final (result, message) in [
    (PurchaseResult.cancelled, 'Purchase cancelled.'),
    (PurchaseResult.unavailable, "Purchases aren't available"),
    (PurchaseResult.failed, 'Purchase failed'),
    (PurchaseResult.notEntitled, 'Premium did not activate'),
  ]) {
    testWidgets('${result.name}: explains and stays free', (tester) async {
      await pump(tester, result);
      await tapText(tester, 'Upgrade to Premium');
      expect(find.textContaining(message), findsOneWidget);
      expect(find.text('🔓 Free'), findsOneWidget);
      expect(container.read(isPremiumProvider), isFalse);
    });
  }

  testWidgets('restore that finds a purchase unlocks', (tester) async {
    await pump(tester, PurchaseResult.failed, restoreFinds: true);
    await tapText(tester, 'Restore Purchases');
    expect(find.text('✅ Premium restored!'), findsOneWidget);
    expect(container.read(isPremiumProvider), isTrue);
  });

  testWidgets('grace period is shown and offers renewal', (tester) async {
    await pump(tester, PurchaseResult.failed,
        storage: FakeStorage(
            sub: SubscriptionState(
                isPremium: true,
                expiresAt: DateTime.now().subtract(const Duration(days: 1)))));
    expect(find.textContaining('grace period'), findsOneWidget);
    expect(find.text('Renew Premium'), findsOneWidget);
  });

  testWidgets('language setting saves to the profile', (tester) async {
    final storage = await pump(tester, PurchaseResult.failed);
    await tester.tap(find.byKey(const ValueKey('language_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('తెలుగు').last);
    await tester.pumpAndSettle();
    expect(storage.profile?.language, 'te');
    expect(container.read(languageProvider), 'te');
  });
}

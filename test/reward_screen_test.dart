import 'package:ai_explorer/core/purchases/subscription_provider.dart';
import 'package:ai_explorer/curriculum/episode_controller.dart';
import 'package:ai_explorer/features/reward/reward_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_storage.dart';

void main() {
  Future<void> pump(WidgetTester tester, String id) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [hiveStorageServiceProvider.overrideWithValue(FakeStorage())],
      child: MaterialApp(
          home: RewardScreen(episodeId: id, badges: const ['pattern_spotter'])),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('offers the next episode when the world has one', (tester) async {
    await pump(tester, 'pf_ep01');
    expect(find.text('Next Adventure ▶️'), findsOneWidget);
    expect(find.text('Back to Worlds 🗺️'), findsOneWidget);
    expect(find.text('Pattern Spotter'), findsOneWidget);
  });

  testWidgets('last episode only offers the way back', (tester) async {
    await pump(tester, 'pf_ep02');
    expect(find.text('Next Adventure ▶️'), findsNothing);
    expect(find.textContaining('needs Premium'), findsNothing);
    expect(find.text('Back to Worlds 🗺️'), findsOneWidget);
  });

  test('isPremiumProvider follows the cached entitlement', () {
    final c = ProviderContainer(overrides: [
      hiveStorageServiceProvider.overrideWithValue(FakeStorage()),
    ]);
    addTearDown(c.dispose);
    expect(c.read(isPremiumProvider), isFalse);
  });
}

import 'package:ai_explorer/features/reward/reward_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, String id) async {
    await tester.pumpWidget(MaterialApp(
        home: RewardScreen(episodeId: id, badges: const ['pattern_spotter'])));
    await tester.pumpAndSettle();
  }

  testWidgets('offers the next episode when the world has one', (tester) async {
    await pump(tester, 'pf_ep01');
    expect(find.text('Next Adventure ▶️'), findsOneWidget);
    expect(find.text('Back to Worlds 🗺️'), findsOneWidget);
  });

  testWidgets('last episode only offers the way back', (tester) async {
    await pump(tester, 'pf_ep02');
    expect(find.text('Next Adventure ▶️'), findsNothing);
    expect(find.text('Back to Worlds 🗺️'), findsOneWidget);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:ai_explorer/core/security/pin_service.dart';
import 'package:ai_explorer/core/storage/models/subscription_state.dart';
import 'package:ai_explorer/curriculum/models/episode_script.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PIN is hashed and verifies', () {
    final h = PinService.hash('1234');
    expect(h, isNot('1234'));
    expect(PinService.verify('1234', h), isTrue);
    expect(PinService.verify('4321', h), isFalse);
  });

  group('SubscriptionState grace period', () {
    test('free user is not active', () {
      expect(const SubscriptionState().isActiveWithGrace, isFalse);
    });
    test('no expiry (lifetime) is active', () {
      expect(const SubscriptionState(isPremium: true).isActiveWithGrace, isTrue);
    });
    test('expired 2 days ago is still active, 4 days ago is not', () {
      final now = DateTime.now();
      expect(
        SubscriptionState(
                isPremium: true, expiresAt: now.subtract(const Duration(days: 2)))
            .isActiveWithGrace,
        isTrue,
      );
      expect(
        SubscriptionState(
                isPremium: true, expiresAt: now.subtract(const Duration(days: 4)))
            .isActiveWithGrace,
        isFalse,
      );
    });
    test('JSON round trip (used for Hive persistence)', () {
      final s = SubscriptionState(
          isPremium: true,
          productId: 'ai_explorer_monthly',
          expiresAt: DateTime.utc(2027, 1, 1));
      final back = SubscriptionState.fromJson(
          jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(back, s);
    });
  });

  test('pf_ep01.json parses into an EpisodeScript', () {
    final raw =
        File('assets/episodes/pattern_forest/pf_ep01.json').readAsStringSync();
    final ep = EpisodeScript.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    expect(ep.id, 'pf_ep01');
    expect(ep.steps, isNotEmpty);
    expect(ep.steps.last.type, StepType.reward);
    for (final s in ep.steps.where((s) => s.type == StepType.speak)) {
      expect(s.intents, isNotEmpty);
      expect(s.fallback, isNotNull);
    }
  });
}

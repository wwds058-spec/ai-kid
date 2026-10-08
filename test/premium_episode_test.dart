import 'package:ai_explorer/core/audio/audio_service.dart';
import 'package:ai_explorer/core/speech/speech_service.dart';
import 'package:ai_explorer/core/storage/models/subscription_state.dart';
import 'package:ai_explorer/curriculum/episode_controller.dart';
import 'package:ai_explorer/curriculum/models/episode_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_storage.dart';

class _Audio extends Fake implements AudioService {
  final played = <String>[];
  @override
  Future<void> play(String lineId, {String lang = 'en'}) async =>
      played.add(lineId);
}

class _Speech extends Fake implements SpeechService {
  @override
  Future<bool> startListening(
          {required String localeId,
          required void Function(String) onResult}) async =>
      true;
  @override
  Future<void> stopListening() async {}
  @override
  void dispose() {}
}

/// Loads the real shipped episode JSON through the real EpisodeLoader.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(EpisodeState, _Audio)> start(String id, SubscriptionState sub) async {
    final audio = _Audio();
    final c = ProviderContainer(overrides: [
      hiveStorageServiceProvider.overrideWithValue(FakeStorage(sub: sub)),
      audioServiceProvider.overrideWithValue(audio),
      speechServiceProvider.overrideWithValue(_Speech()),
    ]);
    addTearDown(c.dispose);
    c.listen(episodeControllerProvider(id), (_, __) {});
    await c.read(episodeControllerProvider(id).notifier).start();
    return (c.read(episodeControllerProvider(id)), audio);
  }

  test('ml_ep01 is locked for a free user and plays nothing', () async {
    final (state, audio) = await start('ml_ep01', const SubscriptionState());
    expect(state, isA<EpisodeLocked>());
    expect(audio.played, isEmpty);
  });

  test('ml_ep01 plays for a subscriber', () async {
    final (state, audio) =
        await start('ml_ep01', const SubscriptionState(isPremium: true));
    expect(state, isA<EpisodeRunning>());
    expect(audio.played.first, 'ml_ep01_s1_intro');
  });

  test('ml_ep01 locks again once the subscription is past its grace',
      () async {
    final (state, _) = await start(
        'ml_ep01',
        SubscriptionState(
            isPremium: true,
            expiresAt: DateTime.now().subtract(const Duration(days: 4))));
    expect(state, isA<EpisodeLocked>());
  });

  test('free episode plays without a subscription', () async {
    final (state, _) = await start('pf_ep01', const SubscriptionState());
    expect(state, isA<EpisodeRunning>());
  });
}

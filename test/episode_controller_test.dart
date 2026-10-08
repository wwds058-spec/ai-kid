import 'package:ai_explorer/core/audio/audio_service.dart';
import 'package:ai_explorer/core/speech/speech_service.dart';
import 'package:ai_explorer/core/storage/models/subscription_state.dart';
import 'package:ai_explorer/curriculum/episode_controller.dart';
import 'package:ai_explorer/curriculum/episode_loader.dart';
import 'package:ai_explorer/curriculum/models/episode_script.dart';
import 'package:ai_explorer/curriculum/models/episode_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_storage.dart';

class FakeAudio extends Fake implements AudioService {
  final played = <String>[];
  final langs = <String>{};
  void Function(String lineId)? onPlay;
  @override
  Future<void> play(String lineId, {String lang = 'en'}) async {
    played.add(lineId);
    langs.add(lang);
    onPlay?.call(lineId);
  }
}

class FakeSpeech extends Fake implements SpeechService {
  int started = 0;
  int stopped = 0;
  String? localeId;
  @override
  Future<void> startListening({
    required String localeId,
    required void Function(String transcript) onResult,
  }) async {
    started++;
    this.localeId = localeId;
  }
  @override
  Future<void> stopListening() async => stopped++;
  @override
  void dispose() {}
}

class FakeLoader extends Fake implements EpisodeLoader {
  FakeLoader(this.script);
  final EpisodeScript script;
  @override
  Future<EpisodeScript> load(String episodeId) async => script;
}

EpisodeScript _script({int timeout = 8, bool premium = false}) => EpisodeScript(
      id: 'pf_test',
      world: 'pattern_forest',
      premium: premium,
      title: const {'en': 'Test'},
      steps: [
        const EpisodeStep(
            id: 's1', type: StepType.watch, audio: 'a1', advance: AdvanceMode.auto),
        const EpisodeStep(
            id: 's2', type: StepType.watch, audio: 'a2', advance: AdvanceMode.tap),
        const EpisodeStep(
          id: 's3',
          type: StepType.play,
          audio: 'a3',
          advance: AdvanceMode.correctAnswer,
          gameConfig: GameConfig(answer: 'blue'),
          onWrong: 'wrong',
        ),
        EpisodeStep(
          id: 's4',
          type: StepType.speak,
          audio: 'a4',
          advance: AdvanceMode.speech,
          timeoutSeconds: timeout,
          intents: const [
            IntentResponse(match: 'YES', audio: 'r_yes'),
            IntentResponse(match: 'DONT_KNOW', audio: 'r_dk'),
          ],
          fallback: 'fb',
        ),
        const EpisodeStep(
          id: 's5',
          type: StepType.reward,
          audio: 'a5',
          advance: AdvanceMode.auto,
          badge: 'pattern_spotter',
        ),
      ],
    );

void main() {
  late FakeAudio audio;
  late FakeSpeech speech;
  late FakeStorage storage;
  late ProviderContainer container;

  EpisodeController ctrl() =>
      container.read(episodeControllerProvider('pf_test').notifier);
  EpisodeState st() => container.read(episodeControllerProvider('pf_test'));

  Future<void> boot(
      {int timeout = 8,
      bool premium = false,
      SubscriptionState? sub,
      String lang = 'en'}) async {
    audio = FakeAudio();
    speech = FakeSpeech();
    storage = FakeStorage();
    if (sub != null) storage.sub = sub;
    container = ProviderContainer(overrides: [
      episodeLoaderProvider.overrideWithValue(
          FakeLoader(_script(timeout: timeout, premium: premium))),
      audioServiceProvider.overrideWithValue(audio),
      speechServiceProvider.overrideWithValue(speech),
      hiveStorageServiceProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
    container.listen(episodeControllerProvider('pf_test'), (_, __) {});
    await ctrl().start(lang: lang);
  }

  Future<void> reachSpeakStep() async {
    await ctrl().handleTap();
    await ctrl().handleAnswer('blue');
  }

  test('auto step plays then waits for tap on step 2', () async {
    await boot();
    final s = st() as EpisodeRunning;
    expect(s.stepIndex, 1);
    expect(s.awaitingTap, isTrue);
    expect(audio.played, ['a1', 'a2']);
  });

  test('tap is ignored when not awaiting a tap', () async {
    await boot();
    await ctrl().handleTap();
    await ctrl().handleTap(); // now on answer step; extra tap must do nothing
    expect((st() as EpisodeRunning).stepIndex, 2);
  });

  test('wrong answer plays onWrong and stays; right answer advances', () async {
    await boot();
    await ctrl().handleTap();
    await ctrl().handleAnswer('red');
    expect(audio.played.last, 'wrong');
    expect((st() as EpisodeRunning).stepIndex, 2);
    await ctrl().handleAnswer('blue');
    final s = st() as EpisodeRunning;
    expect(s.stepIndex, 3);
    expect(s.awaitingSpeech, isTrue);
    expect(speech.started, 1);
  });

  test('matched speech plays the intent audio and completes the episode',
      () async {
    await boot();
    await reachSpeakStep();
    await ctrl().handleSpeech('yes');
    expect(audio.played, containsAllInOrder(['a4', 'r_yes', 'a5']));
    final s = st();
    expect(s, isA<EpisodeComplete>());
    expect((s as EpisodeComplete).badgesEarned, ['pattern_spotter']);
    expect(storage.progress['pf_test']!.completed, isTrue);
    expect(storage.progress['pf_test']!.badgesEarned, ['pattern_spotter']);
  });

  test('unrecognised speech plays the step fallback and advances', () async {
    await boot();
    await reachSpeakStep();
    await ctrl().handleSpeech('banana');
    expect(audio.played, contains('fb'));
    expect(st(), isA<EpisodeComplete>());
  });

  test('"i don\'t know" resolves to DONT_KNOW, not NO', () async {
    await boot();
    await reachSpeakStep();
    await ctrl().handleSpeech("i don't know");
    expect(audio.played, contains('r_dk'));
  });

  test('blocked speech replays fallback, stays, and restarts the mic', () async {
    await boot();
    await reachSpeakStep();
    await ctrl().handleSpeech('where do you live');
    expect(audio.played.last, 'generic_fallback');
    final s = st() as EpisodeRunning;
    expect(s.stepIndex, 3);
    expect(s.awaitingSpeech, isTrue);
    expect(speech.started, 2);
  });

  test('disclosure plays safety audio, logs a timestamp only, and advances',
      () async {
    await boot();
    await reachSpeakStep();
    await ctrl().handleSpeech("someone hits me and says don't tell");
    expect(audio.played, contains('safety_tell_grownup'));
    expect(storage.settings.disclosureLog, hasLength(1));
    expect(storage.settings.disclosureLog.single,
        isNot(contains('hits me'))); // no transcript content stored
    expect(st(), isA<EpisodeComplete>());
  });

  test('speech timeout plays fallback and advances; late transcript ignored',
      () async {
    await boot(timeout: 1);
    await reachSpeakStep();
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(audio.played, contains('fb'));
    expect(st(), isA<EpisodeComplete>());
    final playedBefore = audio.played.length;
    await ctrl().handleSpeech('yes'); // arrives after timeout
    expect(audio.played.length, playedBefore);
  });

  test('premium episode without a subscription is locked and plays nothing',
      () async {
    await boot(premium: true);
    expect(st(), isA<EpisodeLocked>());
    expect(audio.played, isEmpty);
  });

  test('premium episode plays for an active subscriber', () async {
    await boot(premium: true, sub: const SubscriptionState(isPremium: true));
    expect(st(), isA<EpisodeRunning>());
  });

  test('Hindi episode plays Hindi audio and listens in hi-IN', () async {
    await boot(lang: 'hi');
    await reachSpeakStep();
    expect(audio.langs, {'hi'});
    expect(speech.localeId, 'hi-IN');
    await ctrl().handleSpeech('हाँ');
    expect(audio.played, contains('r_yes'));
  });

  test('Telugu "I don\'t know" resolves to DONT_KNOW', () async {
    await boot(lang: 'te');
    await reachSpeakStep();
    expect(speech.localeId, 'te-IN');
    await ctrl().handleSpeech('నాకు తెలియదు');
    expect(audio.played, contains('r_dk'));
  });

  test('Aiko shows each line\'s own emotion while it plays', () async {
    await boot();
    final seen = <String, String?>{};
    audio.onPlay = (id) {
      final s = st();
      if (s is EpisodeRunning) seen[id] = s.lineEmotion ?? s.script.steps[s.stepIndex].emotion;
    };
    await ctrl().handleTap();
    await ctrl().handleAnswer('red'); // wrong
    await ctrl().handleAnswer('blue');
    await ctrl().handleSpeech('banana'); // unrecognised → fallback
    expect(seen['wrong'], 'curious');
    expect(seen['fb'], 'normal');
    expect(seen['a3'], 'normal', reason: 'step line uses the step emotion');
  });

  test('reply line shows the emotion of its intent', () async {
    await boot();
    String? replyEmotion;
    audio.onPlay = (id) {
      if (id == 'r_yes') replyEmotion = (st() as EpisodeRunning).lineEmotion;
    };
    await reachSpeakStep();
    await ctrl().handleSpeech('yes');
    expect(replyEmotion, 'happy');
  });
}

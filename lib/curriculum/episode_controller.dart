import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/audio/audio_service.dart';
import '../core/purchases/subscription_provider.dart';
import '../core/safety/safety_layer.dart';
import '../core/speech/intent_router.dart';
import '../core/speech/speech_service.dart';
import '../core/storage/hive_storage_service.dart';
import '../core/storage/models/episode_progress.dart';
import 'episode_lines.dart';
import 'episode_loader.dart';
import 'models/episode_script.dart';
import 'models/episode_state.dart';

part 'episode_controller.g.dart';

/// The central controller for a playing episode.
///
/// Parameterised by episodeId so each episode gets its own provider family slot.
/// UI observes [EpisodeState] and calls [handleTap], [handleAnswer], [handleSpeech].
///
/// Episode lifecycle:
///   loading → [start()] → running (step loop) → complete
@riverpod
class EpisodeController extends _$EpisodeController {
  Timer? _speechTimer;

  @override
  EpisodeState build(String episodeId) {
    ref.onDispose(() => _speechTimer?.cancel());
    return const EpisodeState.loading();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Called once by EpisodePlayerScreen after navigating to it.
  Future<void> start({String lang = 'en'}) async {
    state = const EpisodeState.loading();
    try {
      final script = await ref.read(episodeLoaderProvider).load(episodeId);
      // Belt and braces: the world map hides premium content, but a premium
      // episode must not play from any route without an active entitlement.
      if (script.premium && !ref.read(isPremiumProvider)) {
        state = const EpisodeState.locked();
        return;
      }
      state = EpisodeState.running(script: script, stepIndex: 0, lang: lang);
      await _runStep(script.steps.first);
    } catch (e) {
      state = EpisodeState.error('Failed to load episode: $e');
    }
  }

  /// User tapped the screen (advance TAP steps)
  Future<void> handleTap() async {
    final s = _runningOrNull();
    if (s == null) return;
    if (!s.awaitingTap) return;
    state = s.copyWith(awaitingTap: false);
    await _nextStep();
  }

  /// User submitted a game answer (PLAY steps)
  Future<void> handleAnswer(String answer) async {
    final s = _runningOrNull();
    if (s == null) return;
    if (!s.awaitingAnswer) return;

    final step = s.script.steps[s.stepIndex];
    final correct = step.gameConfig?.answer == answer;

    if (correct) {
      state = s.copyWith(awaitingAnswer: false);
      await _nextStep();
    } else {
      // Play wrong-answer audio and let them try again
      if (step.onWrong != null) {
        await _say(step.onWrong!);
      }
    }
  }

  /// Called by SpeechService when on-device STT produces a transcript.
  Future<void> handleSpeech(String transcript) async {
    final s = _runningOrNull();
    if (s == null) return;
    if (!s.awaitingSpeech) return;

    _speechTimer?.cancel();
    await ref.read(speechServiceProvider).stopListening();
    state = s.copyWith(awaitingSpeech: false);

    // ── Safety layer ──────────────────────────────────────────────────────
    final safety = ref.read(safetyLayerProvider).validate(transcript);

    switch (safety) {
      case SafeSpeech():
        await _processIntent(transcript, s);

      case BlockedSpeech(audioOverride: final audio):
        // Play fallback, stay on same step, re-enable speech
        await _say(audio);
        state = (state as EpisodeRunning)
            .copyWith(awaitingSpeech: true, lineEmotion: null);
        _startSpeechTimeout();
        _startListening();

      case DisclosureSpeech(audioOverride: final audio):
        // Play "tell a grown-up", log event (no content), advance
        await _say(audio);
        _logDisclosure();
        await _nextStep();
    }
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _runStep(EpisodeStep step) async {
    final s = _runningOrNull();
    if (s == null) return;

    // Parent turned voice answers off: never open the mic. Skip the whole
    // speaking step (its prompt asks for an answer and its fallback lines
    // assume the child spoke).
    if (step.type == StepType.speak &&
        !ref.read(hiveStorageServiceProvider).getSettings().voiceEnabled) {
      await _nextStep();
      return;
    }

    // Set Aiko emotion (UI observes this separately via aikoController)
    // We emit it on state so EpisodePlayerScreen can forward it
    state = s.copyWith(
        awaitingSpeech: false,
        awaitingTap: false,
        awaitingAnswer: false,
        lineEmotion: null);

    // Play the step's audio
    await ref.read(audioServiceProvider).play(step.audio, lang: s.lang);

    // Wait for audio to finish before advancing (for AUTO)
    // For other advance modes, set the awaiting flag

    switch (step.advance) {
      case AdvanceMode.auto:
        await _nextStep();

      case AdvanceMode.tap:
        state = (state as EpisodeRunning).copyWith(awaitingTap: true);

      case AdvanceMode.correctAnswer:
        state = (state as EpisodeRunning).copyWith(awaitingAnswer: true);

      case AdvanceMode.speech:
        state = (state as EpisodeRunning).copyWith(awaitingSpeech: true);
        _startSpeechTimeout();
        _startListening();
    }
  }

  /// Start the microphone — transcript delivered via [handleSpeech].
  void _startListening() {
    final running = _runningOrNull();
    if (running == null) return;
    ref.read(speechServiceProvider).startListening(
          localeId: speechLocale(running.lang),
          onResult: handleSpeech,
        );
  }

  Future<void> _nextStep() async {
    final s = _runningOrNull();
    if (s == null) return;

    final nextIndex = s.stepIndex + 1;

    if (nextIndex >= s.script.steps.length) {
      // Episode complete — save progress
      await _saveProgress(s);
      state = EpisodeState.complete(
        episodeId: episodeId,
        badgesEarned: _collectBadges(s.script),
      );
      return;
    }

    state = s.copyWith(stepIndex: nextIndex);
    await _runStep(s.script.steps[nextIndex]);
  }

  Future<void> _processIntent(String transcript, EpisodeRunning s) async {
    final step = s.script.steps[s.stepIndex];
    final candidates = step.intents.map((i) => i.match).toList();

    final intent = ref.read(intentRouterProvider).match(
          transcript: transcript,
          candidates: candidates,
        );

    final matched = step.intents.where((i) => i.match == intent).firstOrNull;
    final audioId = matched?.audio ?? step.fallback ?? 'generic_fallback';

    await _say(audioId);
    await _nextStep();
  }

  /// Play a reply/feedback line, showing its emotion while it plays.
  Future<void> _say(String lineId) async {
    final s = _runningOrNull();
    if (s == null) return;
    state = s.copyWith(lineEmotion: emotionOfLine(s.script, lineId));
    await ref.read(audioServiceProvider).play(lineId, lang: s.lang);
  }

  void _startSpeechTimeout() {
    final s = _runningOrNull();
    if (s == null) return;
    final step = s.script.steps[s.stepIndex];
    _speechTimer = Timer(Duration(seconds: step.timeoutSeconds), () async {
      // Timeout — stop mic, play fallback, advance. Clear the awaiting flag
      // first so a late transcript can't be applied to the next step.
      final current = _runningOrNull();
      if (current == null || !current.awaitingSpeech) return;
      state = current.copyWith(awaitingSpeech: false);
      await ref.read(speechServiceProvider).stopListening();
      final fallback = step.fallback ?? 'generic_fallback';
      await _say(fallback);
      await _nextStep();
    });
  }

  List<String> _collectBadges(EpisodeScript script) {
    return script.steps
        .where((s) => s.type == StepType.reward && s.badge != null)
        .map((s) => s.badge!)
        .toList();
  }

  Future<void> _saveProgress(EpisodeRunning s) async {
    final storage = ref.read(hiveStorageServiceProvider);
    final existing = storage.getProgress(episodeId);
    await storage.saveProgress(
      EpisodeProgress(
        episodeId: episodeId,
        completed: true,
        lastStepIndex: s.script.steps.length - 1,
        badgesEarned: [
          ...?existing?.badgesEarned,
          ..._collectBadges(s.script),
        ],
        lastPlayedAt: DateTime.now(),
        totalPlaySeconds: (existing?.totalPlaySeconds ?? 0),
      ),
    );
  }

  void _logDisclosure() {
    // Log timestamp only — no transcript content stored
    final storage = ref.read(hiveStorageServiceProvider);
    final settings = storage.getSettings();
    final log = [...settings.disclosureLog, DateTime.now().toIso8601String()];
    storage.saveSettings(settings.copyWith(disclosureLog: log));
  }

  EpisodeRunning? _runningOrNull() =>
      state is EpisodeRunning ? state as EpisodeRunning : null;
}

// ── Storage provider ─────────────────────────────────────────────────────────

@riverpod
HiveStorageService hiveStorageService(HiveStorageServiceRef ref) =>
    HiveStorageService();

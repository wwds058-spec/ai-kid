import 'package:freezed_annotation/freezed_annotation.dart';
import 'episode_script.dart';

part 'episode_state.freezed.dart';

/// The runtime state of the EpisodeController.
/// UI rebuilds only when this changes.
@freezed
class EpisodeState with _$EpisodeState {
  // ── Loading ──────────────────────────────────────────────────────────────
  const factory EpisodeState.loading() = EpisodeLoading;

  // ── Running ──────────────────────────────────────────────────────────────
  const factory EpisodeState.running({
    required EpisodeScript script,
    required int stepIndex,
    @Default(false) bool awaitingSpeech,
    @Default(false) bool awaitingTap,
    @Default(false) bool awaitingAnswer,
    @Default('en') String lang,
  }) = EpisodeRunning;

  // ── Complete ─────────────────────────────────────────────────────────────
  const factory EpisodeState.complete({
    required String episodeId,
    required List<String> badgesEarned,
  }) = EpisodeComplete;

  // ── Locked ───────────────────────────────────────────────────────────────
  /// Premium episode opened without an active subscription.
  const factory EpisodeState.locked() = EpisodeLocked;

  // ── Error ────────────────────────────────────────────────────────────────
  const factory EpisodeState.error(String message) = EpisodeError;
}

extension EpisodeStateX on EpisodeState {
  EpisodeStep? get currentStep => maybeWhen(
        running: (script, stepIndex, _, __, ___, ____) =>
            script.steps[stepIndex],
        orElse: () => null,
      );
}

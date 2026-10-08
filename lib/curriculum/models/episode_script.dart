import 'package:freezed_annotation/freezed_annotation.dart';

part 'episode_script.freezed.dart';
part 'episode_script.g.dart';

// ─── Step types ──────────────────────────────────────────────────────────────

enum StepType { watch, play, speak, reward }

enum AdvanceMode { auto, tap, correctAnswer, speech }

// ─── Intent match inside a SPEAK step ────────────────────────────────────────

@freezed
abstract class IntentResponse with _$IntentResponse {
  const factory IntentResponse({
    required String match,  // e.g. 'WHAT_IS_PATTERN'
    required String audio,  // audio line id
    /// Aiko's emotion while the reply plays (one of AikoWidget.emotionIndex)
    @Default('excited') String emotion,
  }) = _IntentResponse;

  factory IntentResponse.fromJson(Map<String, dynamic> json) =>
      _$IntentResponseFromJson(json);
}

// ─── Game config for PLAY steps ──────────────────────────────────────────────

@freezed
abstract class GameConfig with _$GameConfig {
  const factory GameConfig({
    @Default([]) List<String> items,
    String? answer,
    @Default({}) Map<String, dynamic> extra,
  }) = _GameConfig;

  factory GameConfig.fromJson(Map<String, dynamic> json) =>
      _$GameConfigFromJson(json);
}

// ─── Single step ─────────────────────────────────────────────────────────────

@freezed
abstract class EpisodeStep with _$EpisodeStep {
  const factory EpisodeStep({
    required String id,
    required StepType type,
    required String audio,         // base audio line id (localised by AudioService)
    @Default('idle') String emotion,   // Aiko pose; see AikoWidget.emotionIndex
    String? scene,                 // background scene key
    required AdvanceMode advance,
    // PLAY
    String? game,
    GameConfig? gameConfig,
    String? onWrong,              // audio id to play on wrong answer
    // SPEAK
    @Default([]) List<IntentResponse> intents,
    String? fallback,             // audio id for unrecognised speech
    @Default(8) int timeoutSeconds,
    // REWARD
    String? badge,
  }) = _EpisodeStep;

  factory EpisodeStep.fromJson(Map<String, dynamic> json) =>
      _$EpisodeStepFromJson(json);
}

// ─── Full episode script ──────────────────────────────────────────────────────

@freezed
abstract class EpisodeScript with _$EpisodeScript {
  const factory EpisodeScript({
    required String id,
    required String world,
    required Map<String, String> title,  // { 'en': '...', 'hi': '...', 'te': '...' }
    @Default(false) bool premium,
    required List<EpisodeStep> steps,
  }) = _EpisodeScript;

  factory EpisodeScript.fromJson(Map<String, dynamic> json) =>
      _$EpisodeScriptFromJson(json);
}

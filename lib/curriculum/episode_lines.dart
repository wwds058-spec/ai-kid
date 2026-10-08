/// Every line Aiko can speak, with the emotion she shows while speaking it.
///
/// This is the single link between content, animation and voice recording:
/// the episode player shows [EpisodeLine.emotion] while the line plays, and
/// the studio recording script directs the voice actor with the same value
/// (checked against docs/audio_script_en.csv by tests).
library;

import 'models/episode_script.dart';

enum LineKind { step, wrong, reply, fallback, shared }

class EpisodeLine {
  final String id;
  final String emotion;
  final LineKind kind;

  /// Step the line belongs to (null for shared engine lines).
  final String? stepId;

  const EpisodeLine(this.id, this.emotion, this.kind, [this.stepId]);
}

/// "Oops!" after a wrong game answer: playful, never a scolding.
const kWrongAnswerEmotion = 'oops';

/// Calm when Aiko didn't understand or the child stayed silent.
const kFallbackEmotion = 'idle';

/// Lines the engine plays regardless of episode content.
const kSharedLines = <EpisodeLine>[
  EpisodeLine('generic_fallback', 'idle', LineKind.shared),
  EpisodeLine('generic_too_long', 'idle', LineKind.shared),
  // Calm and warm — never alarmed — when a child may be disclosing harm.
  EpisodeLine('safety_tell_grownup', 'idle', LineKind.shared),
];

List<EpisodeLine> linesOf(EpisodeScript script) => [
      for (final s in script.steps) ...[
        EpisodeLine(s.audio, s.emotion, LineKind.step, s.id),
        if (s.onWrong != null)
          EpisodeLine(s.onWrong!, kWrongAnswerEmotion, LineKind.wrong, s.id),
        for (final i in s.intents)
          EpisodeLine(i.audio, i.emotion, LineKind.reply, s.id),
        if (s.fallback != null)
          EpisodeLine(s.fallback!, kFallbackEmotion, LineKind.fallback, s.id),
      ]
    ];

/// Emotion to show while [lineId] plays (shared lines included).
String? emotionOfLine(EpisodeScript script, String lineId) {
  for (final l in [...linesOf(script), ...kSharedLines]) {
    if (l.id == lineId) return l.emotion;
  }
  return null;
}

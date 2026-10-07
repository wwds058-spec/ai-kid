import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'intent_router.g.dart';

/// Matches a child's speech transcript to one of ~30 predefined intents
/// per episode step. No ML, no cloud — pure string matching.
///
/// Strategy:
///  1. Try exact phrase match (trimmed, lowercased)
///  2. Try keyword match: does the transcript contain any keyword for this intent?
///  3. Fall back to 'UNKNOWN' → episode uses its fallback audio
class IntentRouter {
  /// Map of intent name → list of trigger keywords/phrases
  /// These are global; episode-specific ones can override via [extraKeywords].
  static const Map<String, List<String>> _intentKeywords = {
    'YES':              ['yes', 'yeah', 'yep', 'haan', 'ha', 'ok', 'okay'],
    'NO':               ['no', 'nahi', 'nope', 'nah'],
    'DONT_KNOW':        ["don't know", "dont know", "i don't know", 'no idea',
                         'not sure', 'mujhe nahi pata', 'teliyadu'],
    'WHAT_IS_PATTERN':  ['what is pattern', 'what pattern', 'pattern kya hai'],
    'WHAT_IS_AI':       ['what is ai', 'what is artificial intelligence',
                         'ai kya hai'],
    'WHAT_IS_DATA':     ['what is data', 'data kya hai'],
    'REPEAT':           ['repeat', 'again', 'phir se', 'again please'],
    'HELP':             ['help', 'help me', 'i need help', 'madad'],
    'MORE':             ['more', 'tell me more', 'aur batao'],
    'DONE':             ['done', 'finished', 'complete', 'ho gaya'],
    'COLORS':           ['red', 'blue', 'green', 'yellow', 'orange', 'purple',
                         'color', 'colour'],
    'SHAPES':           ['circle', 'square', 'triangle', 'rectangle', 'shape'],
    'NUMBERS':          ['one', 'two', 'three', 'four', 'five', 'number'],
    'ANIMALS':          ['cat', 'dog', 'bird', 'fish', 'animal'],
    'SKIP':             ['skip', 'next', 'aage', 'go next'],
  };

  /// Match [transcript] against [candidates] (the intents valid for this step).
  /// Returns the matched intent name or 'UNKNOWN'.
  String match({
    required String transcript,
    required List<String> candidates,
    Map<String, List<String>> extraKeywords = const {},
  }) {
    final lower = transcript.toLowerCase().trim();
    if (lower.isEmpty) return 'UNKNOWN';

    // Merge global + episode-specific keywords
    final allKeywords = {
      ..._intentKeywords,
      ...extraKeywords,
    };

    // Only check intents that are valid for this step
    for (final intent in candidates) {
      final keywords = allKeywords[intent] ?? [];
      for (final kw in keywords) {
        if (lower == kw || lower.contains(kw)) {
          return intent;
        }
      }
    }

    return 'UNKNOWN';
  }
}

@riverpod
IntentRouter intentRouter(IntentRouterRef ref) => IntentRouter();

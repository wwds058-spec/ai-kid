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
  /// Map of intent name → list of trigger keywords/phrases.
  /// These are global; episode-specific ones can override via [extraKeywords].
  ///
  /// On-device STT returns native script for hi-IN (Devanagari) and te-IN
  /// (Telugu), so each intent lists English, romanised and native-script
  /// forms. Native-script entries are drafts: review with native speakers.
  static const Map<String, List<String>> _intentKeywords = {
    'YES':              ['yes', 'yeah', 'yep', 'haan', 'ha', 'ok', 'okay',
                         'हाँ', 'हां', 'जी', 'ठीक है',
                         'అవును', 'ఔను', 'సరే'],
    'NO':               ['no', 'nahi', 'nope', 'nah',
                         'नहीं', 'ना', 'లేదు', 'కాదు'],
    'DONT_KNOW':        ["don't know", "dont know", "i don't know", 'no idea',
                         'not sure', 'mujhe nahi pata', 'teliyadu',
                         'पता नहीं', 'नहीं पता', 'मालूम नहीं',
                         'తెలియదు', 'నాకు తెలియదు'],
    'WHAT_IS_PATTERN':  ['what is pattern', 'what pattern', 'pattern kya hai',
                         'पैटर्न क्या है', 'पैटर्न क्या होता है',
                         'ప్యాటర్న్ అంటే ఏమిటి', 'ప్యాటర్న్ అంటే ఏంటి'],
    'WHAT_IS_AI':       ['what is ai', 'what is artificial intelligence',
                         'ai kya hai', 'एआई क्या है', 'AI क्या है',
                         'ఏఐ అంటే ఏమిటి', 'AI అంటే ఏమిటి'],
    'WHAT_IS_DATA':     ['what is data', 'data kya hai', 'डेटा क्या है',
                         'డేటా అంటే ఏమిటి'],
    'REPEAT':           ['repeat', 'again', 'phir se', 'again please',
                         'फिर से', 'दोबारा', 'మళ్లీ', 'మళ్ళీ చెప్పు'],
    'HELP':             ['help', 'help me', 'i need help', 'madad',
                         'मदद', 'मेरी मदद करो', 'సహాయం', 'సహాయం చేయి'],
    'MORE':             ['more', 'tell me more', 'aur batao',
                         'और बताओ', 'ఇంకా', 'ఇంకా చెప్పు'],
    'DONE':             ['done', 'finished', 'complete', 'ho gaya',
                         'हो गया', 'खत्म', 'అయిపోయింది', 'పూర్తయింది'],
    'COLORS':           ['red', 'blue', 'green', 'yellow', 'orange', 'purple',
                         'color', 'colour',
                         'रंग', 'लाल', 'नीला', 'हरा', 'पीला',
                         'రంగు', 'రంగులు', 'ఎరుపు', 'నీలం', 'ఆకుపచ్చ', 'పసుపు'],
    'SHAPES':           ['circle', 'square', 'triangle', 'rectangle', 'shape',
                         'आकार', 'गोला', 'वृत्त', 'वर्ग', 'त्रिभुज',
                         'ఆకారం', 'ఆకారాలు', 'వృత్తం', 'చతురస్రం', 'త్రిభుజం'],
    'NUMBERS':          ['one', 'two', 'three', 'four', 'five', 'number',
                         'एक', 'दो', 'तीन', 'चार', 'पांच', 'पाँच', 'संख्या',
                         'ఒకటి', 'రెండు', 'మూడు', 'నాలుగు', 'ఐదు', 'సంఖ్య'],
    'ANIMALS':          ['cat', 'dog', 'bird', 'fish', 'animal',
                         'बिल्ली', 'कुत्ता', 'चिड़िया', 'मछली', 'जानवर',
                         'పిల్లి', 'కుక్క', 'పక్షి', 'చేప', 'జంతువు'],
    'SKIP':             ['skip', 'next', 'aage', 'go next',
                         'आगे', 'अगला', 'తర్వాత', 'ముందుకు'],
    'MUSIC':            ['music', 'song', 'sing', 'dance', 'drum', 'clap',
                         'gaana', 'naach',
                         'संगीत', 'गाना', 'गाने', 'नाच', 'नाचना', 'ढोल', 'ताली',
                         'సంగీతం', 'పాట', 'పాటలు', 'డ్యాన్స్', 'నాట్యం', 'డప్పు', 'చప్పట్లు'],
  };

  /// Intent names understood without episode-specific [extraKeywords].
  static Set<String> get knownIntents => _intentKeywords.keys.toSet();

  /// Keywords for [intent] (for tests and review tooling).
  static List<String> keywordsFor(String intent) =>
      _intentKeywords[intent] ?? const [];

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

    // Only check intents that are valid for this step. Keywords must match as
    // whole words/phrases ('no' must not fire inside 'know'), and the longest
    // matching keyword wins so "i don't know" beats a shorter 'no'.
    String? best;
    var bestLength = 0;
    for (final intent in candidates) {
      for (final kw in allKeywords[intent] ?? const <String>[]) {
        if (kw.length > bestLength && _containsPhrase(lower, kw)) {
          best = intent;
          bestLength = kw.length;
        }
      }
    }
    if (best != null) return best;

    return 'UNKNOWN';
  }

  /// True if [phrase] occurs in [text] bounded by non-letter/digit characters.
  /// Combining marks (\p{M}) count as part of a word: Indic vowel signs are
  /// marks, so 'हा' must not match inside 'हाँ'.
  static bool _containsPhrase(String text, String phrase) => RegExp(
        '(?<![\\p{L}\\p{M}\\p{N}\'])${RegExp.escape(phrase)}(?![\\p{L}\\p{M}\\p{N}\'])',
        unicode: true,
      ).hasMatch(text);
}

@riverpod
IntentRouter intentRouter(IntentRouterRef ref) => IntentRouter();

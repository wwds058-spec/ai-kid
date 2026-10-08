import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'safety_layer.g.dart';

/// 4-check safety layer for child speech input.
/// Returns null if the input is safe, or a SafetyResult if action is needed.
class SafetyLayer {
  // ── Check 1: length filter ──────────────────────────────────────────────
  static const _maxChars = 120;

  // ── Check 2: blocklist ─────────────────────────────────────────────────
  // Keep this minimal — false positives block learning. Add with care.
  //
  // Hindi/Telugu entries are DRAFTS for native-speaker and child-safety
  // review (see docs/TRANSLATION_REVIEW.md). Avoid single words that are
  // also everyday speech: Hindi 'पता' means 'address' but also appears in
  // 'पता नहीं' ("I don't know"), so only 'घर का पता' is listed.
  static const _blocklist = <String>[
    // en
    'address', 'phone number', 'location', 'where do you live',
    // hi (Devanagari + romanised)
    'घर का पता', 'फ़ोन नंबर', 'फोन नंबर', 'मोबाइल नंबर',
    'कहाँ रहते हो', 'कहां रहते हो', 'ghar ka pata', 'kahan rehte ho',
    // te
    'చిరునామా', 'ఫోన్ నంబర్', 'మొబైల్ నంబర్', 'ఎక్కడ ఉంటావు', 'ఎక్కడ ఉంటారు',
  ];

  // ── Check 3: disclosure detector ──────────────────────────────────────
  // Signals a child may be sharing something sensitive about their safety.
  static const _disclosureKeywords = <String>[
    // en
    'hurts me', 'hits me', 'scared of', 'don\'t tell', 'secret with',
    'touched me', 'no one knows',
    // hi (Devanagari + romanised)
    'मुझे मारता', 'मुझे मारती', 'मुझे मारते', 'दर्द देता', 'दर्द देती',
    'डर लगता है', 'किसी को मत बताना', 'मत बताना', 'मुझे छुआ',
    'कोई नहीं जानता', 'mujhe maarta', 'mujhe marta', 'mat batana',
    // te
    'నన్ను కొడతాడు', 'నన్ను కొడుతుంది', 'నన్ను కొడతారు', 'నొప్పి పెడతాడు',
    'భయం వేస్తుంది', 'భయంగా ఉంది', 'ఎవరికీ చెప్పకు', 'చెప్పొద్దు',
    'నన్ను తాకాడు', 'ఎవరికీ తెలియదు',
  ];

  /// Read-only views for tests and review tooling.
  static List<String> get blocklist => _blocklist;
  static List<String> get disclosureKeywords => _disclosureKeywords;

  /// Returns [SafetyResult.safe] if OK to process,
  /// or a result with [audioOverride] pointing to the pre-recorded response.
  SafetyResult validate(String transcript) {
    // 1. Length
    if (transcript.length > _maxChars) {
      return const SafetyResult.blocked('generic_too_long');
    }

    final lower = transcript.toLowerCase();

    // 2. Blocklist
    for (final term in _blocklist) {
      if (lower.contains(term)) {
        return const SafetyResult.blocked('generic_fallback');
      }
    }

    // 3. Disclosure detector
    for (final keyword in _disclosureKeywords) {
      if (lower.contains(keyword)) {
        // Route to pre-recorded "tell a grown-up" response
        // NO audio upload, NO cloud logging — just play the safety audio
        return const SafetyResult.disclosure('safety_tell_grownup');
      }
    }

    // 4. Pass
    return const SafetyResult.safe();
  }
}

sealed class SafetyResult {
  const SafetyResult();
  const factory SafetyResult.safe() = SafeSpeech;
  const factory SafetyResult.blocked(String audioOverride) = BlockedSpeech;
  const factory SafetyResult.disclosure(String audioOverride) = DisclosureSpeech;
}

class SafeSpeech extends SafetyResult {
  const SafeSpeech();
}

class BlockedSpeech extends SafetyResult {
  final String audioOverride;
  const BlockedSpeech(this.audioOverride);
}

class DisclosureSpeech extends SafetyResult {
  final String audioOverride;
  const DisclosureSpeech(this.audioOverride);
}

@riverpod
SafetyLayer safetyLayer(SafetyLayerRef ref) => SafetyLayer();

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'safety_layer.g.dart';

/// 4-check safety layer for child speech input.
/// Returns null if the input is safe, or a SafetyResult if action is needed.
class SafetyLayer {
  // ── Check 1: length filter ──────────────────────────────────────────────
  static const _maxChars = 120;

  // ── Check 2: blocklist ─────────────────────────────────────────────────
  // Keep this minimal — false positives block learning. Add with care.
  static const _blocklist = <String>[
    'address', 'phone number', 'location', 'where do you live',
  ];

  // ── Check 3: disclosure detector ──────────────────────────────────────
  // Signals a child may be sharing something sensitive about their safety.
  static const _disclosureKeywords = <String>[
    'hurts me', 'hits me', 'scared of', 'don\'t tell', 'secret with',
    'touched me', 'no one knows',
  ];

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

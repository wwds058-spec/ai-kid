import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

part 'speech_service.g.dart';

/// Wraps [SpeechToText] with simple start/stop lifecycle.
///
/// Notes:
///  • On-device only — no audio leaves the device.
///  • Requires RECORD_AUDIO permission (declared in AndroidManifest).
///  • In the episode flow, [EpisodeController] calls [startListening] when a
///    SPEAK step begins, and [stopListening] after [onResult] fires or on timeout.
class SpeechService {
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _initialized = false;

  /// Returns true if the plugin initialised successfully.
  Future<bool> init() async {
    if (_initialized) return true;
    _initialized = await _stt.initialize(
      onError: (e) => _onError(e.errorMsg),
      onStatus: (_) {},
    );
    return _initialized;
  }

  /// Starts a single-utterance listen session.
  ///
  /// [localeId] — BCP-47 locale, e.g. 'en-IN', 'hi-IN', 'te-IN'.
  ///              Ignored if the device doesn't support it (falls back to default).
  /// [onResult]  — called with the best final transcript once speech ends.
  Future<void> startListening({
    required String localeId,
    required void Function(String transcript) onResult,
  }) async {
    final ready = await init();
    if (!ready || _stt.isListening) return;

    await _stt.listen(
      localeId: localeId,
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 3),
      // Privacy: never send a child's voice to a cloud recogniser. If the
      // device has no offline model for this language, listening fails and
      // the step's timeout fallback plays instead.
      listenOptions: stt.SpeechListenOptions(
        onDevice: true,
        partialResults: false,
        cancelOnError: true,
      ),
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
    );
  }

  Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
  }

  bool get isListening => _stt.isListening;

  void _onError(String message) {
    // Errors are surfaced through the timeout path in EpisodeController —
    // no need to crash the app here.
  }

  void dispose() {
    _stt.cancel();
  }
}

@riverpod
SpeechService speechService(Ref ref) {
  final service = SpeechService();
  ref.onDispose(service.dispose);
  return service;
}

// ── Locale helpers ────────────────────────────────────────────────────────────

/// Map from app language code to a BCP-47 locale understood by speech_to_text.
String speechLocale(String lang) => switch (lang) {
      'hi' => 'hi-IN',
      'te' => 'te-IN',
      _    => 'en-IN',
    };

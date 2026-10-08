import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audio_service.g.dart';

/// Plays pre-recorded audio lines from assets.
///
/// Asset naming convention:
///   assets/audio/{lang}/{line_id}.mp3
///
/// Example:
///   audio line id  = 'pf_ep01_s1'
///   emotion suffix  = not in filename — emotion drives Rive, not audio
///   assets/audio/en/pf_ep01_s1.mp3
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  /// Play a single audio line.
  /// [lineId] — e.g. 'pf_ep01_s1'
  /// [lang]   — 'en' | 'hi' | 'te'
  /// Falls back to the English recording if the [lang] file is missing, so a
  /// gap in a translation never leaves the child in silence.
  Future<void> play(String lineId, {String lang = 'en'}) async {
    for (final path in audioPaths(lineId, lang)) {
      if (await _tryPlay(path)) return;
    }
  }

  /// Asset paths to try, in order, for [lineId] in [lang].
  static List<String> audioPaths(String lineId, String lang) => [
        'assets/audio/$lang/$lineId.mp3',
        if (lang != 'en') 'assets/audio/en/$lineId.mp3',
      ];

  Future<bool> _tryPlay(String path) async {
    try {
      await _player.stop();
      await _player.setAsset(path);
      await _player.play();
      return true;
    } catch (e) {
      // File missing in dev (just_audio may throw PlayerException or
      // PlatformException) — log and continue so the engine doesn't stall
      // ignore: avoid_print
      print('[AudioService] Missing asset: $path — $e');
      return false;
    }
  }

  Future<void> stop() => _player.stop();

  /// Duration of current clip (null if not loaded)
  Duration? get duration => _player.duration;

  /// Stream so UI can show progress bar if desired
  Stream<Duration> get positionStream => _player.positionStream;

  void dispose() => _player.dispose();
}

@riverpod
AudioService audioService(AudioServiceRef ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
}

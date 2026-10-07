import 'package:flutter/services.dart';
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
  Future<void> play(String lineId, {String lang = 'en'}) async {
    final path = 'assets/audio/$lang/$lineId.mp3';
    try {
      await _player.stop();
      await _player.setAsset(path);
      await _player.play();
    } on PlatformException catch (e) {
      // File missing in dev — log and continue so the engine doesn't stall
      // ignore: avoid_print
      print('[AudioService] Missing asset: $path — $e');
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

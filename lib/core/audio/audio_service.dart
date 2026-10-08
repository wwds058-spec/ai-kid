import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audio_service.g.dart';

/// Plays pre-recorded audio lines from assets/audio/{lang}/{line_id}.mp3.
///
/// [play] completes only when the line has really finished (or was replaced
/// by another line / [stop]). Pausing — app sent to background, phone call,
/// another app taking audio focus — does NOT complete it, so the episode
/// waits instead of racing ahead through its steps unattended.
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<AudioInterruptionEvent>? _interruptions;
  bool _pausedByInterruption = false;

  /// Configure the audio session for spoken content and follow system
  /// interruptions (calls, alarms, other apps). Call once at start-up.
  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _interruptions = session.interruptionEventStream.listen((e) {
      if (e.begin) {
        if (_player.playing) {
          _pausedByInterruption = true;
          _player.pause();
        }
      } else if (_pausedByInterruption &&
          e.type != AudioInterruptionType.unknown) {
        _pausedByInterruption = false;
        _player.play();
      }
    });
  }

  /// Play a single audio line ([lang] = 'en' | 'hi' | 'te').
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
    } catch (e) {
      // File missing in dev (just_audio may throw PlayerException or
      // PlatformException) — log and continue so the engine doesn't stall
      // ignore: avoid_print
      print('[AudioService] Missing asset: $path — $e');
      return false;
    }
    final finished = _player.processingStateStream.firstWhere((s) =>
        s == ProcessingState.completed || s == ProcessingState.idle);
    unawaited(_player.play());
    await finished;
    return true;
  }

  /// App going to background: hold the current line where it is.
  Future<void> pause() => _player.pause();

  /// App back in the foreground: continue the held line, if any.
  Future<void> resume() async {
    if (_player.processingState == ProcessingState.ready && !_player.playing) {
      await _player.play();
    }
  }

  Future<void> stop() => _player.stop();

  void dispose() {
    _interruptions?.cancel();
    _player.dispose();
  }
}

@riverpod
AudioService audioService(AudioServiceRef ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
}

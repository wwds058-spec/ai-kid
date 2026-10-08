import 'package:ai_explorer/app/router.dart';
import 'package:ai_explorer/core/audio/audio_service.dart';
import 'package:ai_explorer/core/speech/speech_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Services that own long-lived platform state are only `ref.read` by their
/// users. If they were auto-dispose, Riverpod would dispose them between
/// reads: the router's redirect would fail ("Ref used after dispose") and the
/// audio player / speech recogniser could be torn down mid-episode.
void main() {
  test('router, audio and speech providers are keep-alive', () {
    expect(appRouterProvider.isAutoDispose, isFalse);
    expect(audioServiceProvider.isAutoDispose, isFalse);
    expect(speechServiceProvider.isAutoDispose, isFalse);
  });
}

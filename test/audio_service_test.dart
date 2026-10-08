import 'package:ai_explorer/core/audio/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('localised line falls back to English if its file is missing', () {
    expect(AudioService.audioPaths('pf_ep01_s1_intro', 'hi'), [
      'assets/audio/hi/pf_ep01_s1_intro.mp3',
      'assets/audio/en/pf_ep01_s1_intro.mp3',
    ]);
    expect(AudioService.audioPaths('x', 'en'), ['assets/audio/en/x.mp3']);
  });
}

import 'package:ai_explorer/core/safety/safety_layer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final layer = SafetyLayer();

  test('normal speech is safe', () {
    expect(layer.validate('what is a pattern'), isA<SafeSpeech>());
  });

  test('over-long input is blocked', () {
    final r = layer.validate('a' * 121);
    expect(r, isA<BlockedSpeech>());
    expect((r as BlockedSpeech).audioOverride, 'generic_too_long');
  });

  test('personal-info terms are blocked', () {
    expect(layer.validate('Where do you live'), isA<BlockedSpeech>());
    expect(layer.validate('my phone number is'), isA<BlockedSpeech>());
  });

  test('disclosure routes to the tell-a-grown-up audio', () {
    final r = layer.validate("someone hits me and says don't tell");
    expect(r, isA<DisclosureSpeech>());
    expect((r as DisclosureSpeech).audioOverride, 'safety_tell_grownup');
  });
}

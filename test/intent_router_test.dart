import 'package:ai_explorer/core/speech/intent_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final router = IntentRouter();
  String m(String t, List<String> c) =>
      router.match(transcript: t, candidates: c);

  test('exact and phrase matches', () {
    expect(m('yes', ['YES', 'NO']), 'YES');
    expect(m('  Okay! ', ['YES', 'NO']), 'YES');
    expect(m('what is pattern', ['WHAT_IS_PATTERN', 'YES']), 'WHAT_IS_PATTERN');
  });

  test('empty and unrelated speech is UNKNOWN', () {
    expect(m('', ['YES']), 'UNKNOWN');
    expect(m('banana smoothie', ['YES', 'NO']), 'UNKNOWN');
  });

  test('keywords match whole words only, not substrings', () {
    // "know" contains "no"; "what" contains "ha"; "look" contains "ok".
    expect(m('I know', ['NO', 'YES']), 'UNKNOWN');
    expect(m('what', ['YES']), 'UNKNOWN');
    expect(m('look', ['YES']), 'UNKNOWN');
  });

  test('most specific phrase wins over a shorter keyword', () {
    expect(m("i don't know", ['NO', 'DONT_KNOW', 'YES']), 'DONT_KNOW');
    expect(m('no idea', ['NO', 'DONT_KNOW']), 'DONT_KNOW');
  });

  test('only candidate intents are considered', () {
    expect(m('yes', ['NO']), 'UNKNOWN');
  });

  test('extra keywords override globals', () {
    expect(
      router.match(
        transcript: 'the answer is blue',
        candidates: ['PICK'],
        extraKeywords: {'PICK': ['blue']},
      ),
      'PICK',
    );
  });
}

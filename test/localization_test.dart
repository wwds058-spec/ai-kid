import 'dart:io';

import 'package:ai_explorer/core/safety/safety_layer.dart';
import 'package:ai_explorer/core/speech/intent_router.dart';
import 'package:ai_explorer/curriculum/episode_catalog.dart';
import 'package:ai_explorer/l10n/review_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content.dart';

final _devanagari = RegExp(r'[ऀ-ॿ]');
final _telugu = RegExp(r'[ఀ-౿]');

void main() {
  group('speech keywords', () {
    for (final intent in IntentRouter.knownIntents) {
      test('$intent has Hindi and Telugu script keywords', () {
        final kws = IntentRouter.keywordsFor(intent);
        expect(kws.any(_devanagari.hasMatch), isTrue, reason: '$intent: hi');
        expect(kws.any(_telugu.hasMatch), isTrue, reason: '$intent: te');
      });
    }

    test('no keyword is repeated across intents (ambiguous match)', () {
      final seen = <String, String>{};
      for (final intent in IntentRouter.knownIntents) {
        for (final k in IntentRouter.keywordsFor(intent)) {
          expect(seen.containsKey(k), isFalse,
              reason: '"$k" in both ${seen[k]} and $intent');
          seen[k] = intent;
        }
      }
    });
  });

  group('safety phrases in every language', () {
    final layer = SafetyLayer();

    test('Hindi and Telugu disclosure and personal-info phrases exist', () {
      expect(SafetyLayer.disclosureKeywords.any(_devanagari.hasMatch), isTrue);
      expect(SafetyLayer.disclosureKeywords.any(_telugu.hasMatch), isTrue);
      expect(SafetyLayer.blocklist.any(_devanagari.hasMatch), isTrue);
      expect(SafetyLayer.blocklist.any(_telugu.hasMatch), isTrue);
    });

    for (final phrase in [
      'वो मुझे मारता है',
      'किसी को मत बताना',
      'mujhe maarta hai',
      'అతను నన్ను కొడతాడు',
      'ఎవరికీ చెప్పకు',
    ]) {
      test('disclosure "$phrase" routes to tell-a-grown-up', () {
        expect(layer.validate(phrase), isA<DisclosureSpeech>());
      });
    }

    for (final phrase in ['मेरा फोन नंबर', 'నా ఫోన్ నంబర్']) {
      test('personal info "$phrase" is blocked', () {
        expect(layer.validate(phrase), isA<BlockedSpeech>());
      });
    }

    for (final phrase in [
      'मुझे पता नहीं', // "I don't know" contains पता (address) — must pass
      'నాకు తెలియదు',
      'लाल और नीला',
      'హాయ్ ఐకో',
    ]) {
      test('everyday answer "$phrase" is not blocked', () {
        expect(layer.validate(phrase), isA<SafeSpeech>());
      });
    }
  });

  group('every child-facing translation is flagged for review', () {
    test('every hi/te audio line carries a review note until reviewed', () {
      for (final lang in kLanguages.where((l) => l != 'en')) {
        final notes = loadAudioScriptColumn(lang, 'notes');
        final reviewed = kTranslationReview[lang]!.reviewed;
        for (final e in notes.entries) {
          if (!reviewed) {
            expect(e.value, contains('needs native-speaker review'),
                reason: '$lang/${e.key}');
          }
        }
      }
    });

    test('every supported non-English language has a review entry', () {
      expect(kTranslationReview.keys.toSet(),
          kLanguages.where((l) => l != 'en').toSet());
    });

    test('translations are reviewed before release', () {
      for (final e in kTranslationReview.entries) {
        expect(e.value.reviewed, isTrue,
            reason: '${e.key}: native-speaker review not signed off '
                '(lib/l10n/review_status.dart, docs/TRANSLATION_REVIEW.md)');
        expect(e.value.reviewer, isNotEmpty, reason: e.key);
      }
    }, skip: Platform.environment['RELEASE'] == '1'
        ? false
        : 'only enforced when RELEASE=1');
  });

  test('child-facing screens contain no hard-coded text', () {
    // Anything a child reads must come from AppStrings, so it is translated.
    // A literal with two or more letters that aren't part of a ${...}/$name
    // interpolation.
    final literal = RegExp(r'''Text\(\s*['"]((?:[^'"$]|\$\{[^}]*\}|\$\w+)*)''',
        unicode: true);
    final letters = RegExp(r'\p{L}{2,}', unicode: true);
    String stripInterp(String t) =>
        t.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
    for (final dir in [
      'lib/features/onboarding',
      'lib/features/world_map',
      'lib/features/episode_player',
      'lib/features/reward',
    ]) {
      for (final f in Directory(dir).listSync().whereType<File>()) {
        final src = f.readAsStringSync();
        final hardCoded = literal
            .allMatches(src)
            .map((m) => m.group(1)!)
            .where((t) => letters.hasMatch(stripInterp(t)));
        expect(hardCoded, isEmpty, reason: f.path);
      }
    }
  });
}

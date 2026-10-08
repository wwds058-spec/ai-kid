import 'dart:io';

import 'package:ai_explorer/core/safety/safety_layer.dart';
import 'package:ai_explorer/core/speech/intent_router.dart';
import 'package:ai_explorer/l10n/strings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content.dart';

/// Native-speaker review worksheets: docs/review/review_{hi,te}.csv.
///
/// One row per child-facing string, speech keyword and safety phrase, with a
/// stable id, the English reference, the current text, a SAFETY flag and
/// empty reviewer columns. This test fails if a committed sheet is out of
/// date; regenerate with:  UPDATE_REVIEW=1 flutter test test/review_sheet_test.dart
const _devanagari = r'[ऀ-ॿ]';
const _telugu = r'[ఀ-౿]';

String _csv(List<String> cells) =>
    cells.map((c) => c.contains(RegExp('[",\n]')) ? '"${c.replaceAll('"', '""')}"' : c).join(',');

String buildSheet(String lang) {
  final script = RegExp(lang == 'hi' ? _devanagari : _telugu);
  // Latin-script entries may be English or romanised Hindi/Telugu
  // ('haan', 'mat batana', 'teliyadu'); code can't tell which, so both
  // sheets list them for the reviewer to check their own language's forms.
  final latin = RegExp(r'^[\x00-\x7F]+$');
  String where(String t) => latin.hasMatch(t) ? ' [Latin script: English or romanised]' : '';
  final rows = <List<String>>[];
  void add(String id, String english, String text, String context,
          {bool safety = false}) =>
      rows.add([id, safety ? 'SAFETY' : '', context, english, text, '', '', '']);

  // UI, titles of worlds, rewards
  final en = AppStrings.en.reviewEntries;
  AppStrings.of(lang).reviewEntries.forEach((id, text) =>
      add(id, en[id] ?? '', text, id.startsWith('reward') ? 'badge' : 'button/label'));

  // Episode titles
  for (final f in loadEpisodeFiles()) {
    add('title.${f.script.id}', f.script.title['en'] ?? '',
        f.script.title[lang] ?? '', 'episode title');
  }

  // Aiko dialogue
  final enLines = loadAudioScript('en');
  final emotions = loadAudioScriptColumn('en', 'emotion');
  loadAudioScript(lang).forEach((id, text) => add('audio.$id', enLines[id] ?? '',
      text, 'Aiko says (${emotions[id]})',
      safety: id == 'safety_tell_grownup'));

  // Speech keywords (only this language's script)
  for (final intent in IntentRouter.knownIntents.toList()..sort()) {
    final kws = IntentRouter.keywordsFor(intent)
        .where((k) => script.hasMatch(k) || latin.hasMatch(k))
        .toList();
    for (var i = 0; i < kws.length; i++) {
      add('keyword.$intent.$i', intent, kws[i],
          'a child may say this to mean $intent${where(kws[i])}');
    }
  }

  // Safety phrases (child-safety review required)
  for (final (kind, list) in [
    ('disclosure', SafetyLayer.disclosureKeywords),
    ('personal_info', SafetyLayer.blocklist),
  ]) {
    final local =
        list.where((k) => script.hasMatch(k) || latin.hasMatch(k)).toList();
    for (var i = 0; i < local.length; i++) {
      add('safety.$kind.$i', kind, local[i],
          (kind == 'disclosure'
                  ? 'child may be disclosing harm → calm "tell a grown-up" line'
                  : 'child sharing personal info → gently redirected') +
              where(local[i]),
          safety: true);
    }
  }

  return [
    _csv(['id', 'flag', 'context', 'english_reference', 'current_text',
        'reviewer_ok (Y/N)', 'correction', 'reviewer_notes']),
    for (final r in rows) _csv(r),
  ].join('\n') + '\n';
}

void main() {
  for (final lang in ['hi', 'te']) {
    test('[$lang] review sheet is up to date', () {
      final file = File('docs/review/review_$lang.csv');
      final sheet = buildSheet(lang);
      if (Platform.environment['UPDATE_REVIEW'] == '1') {
        file.writeAsStringSync(sheet);
      }
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), sheet,
          reason: 'content changed: UPDATE_REVIEW=1 flutter test test/review_sheet_test.dart');
    });

    test('[$lang] every safety phrase and the safety line are flagged', () {
      final sheet = buildSheet(lang).split('\n');
      final flagged = sheet.where((l) => l.contains(',SAFETY,')).length;
      expect(flagged, greaterThan(10));
      expect(sheet.where((l) => l.startsWith('audio.safety_tell_grownup,SAFETY')),
          hasLength(1));
    });
  }

  test('romanised safety phrases reach both reviewers', () {
    for (final lang in ['hi', 'te']) {
      final sheet = buildSheet(lang);
      expect(sheet, contains(',mat batana,'), reason: lang);
      expect(sheet, contains(',mujhe maarta,'), reason: lang);
    }
  });
}

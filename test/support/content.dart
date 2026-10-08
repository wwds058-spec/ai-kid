import 'dart:convert';
import 'dart:io';

import 'package:ai_explorer/curriculum/models/episode_script.dart';

/// Audio ids the engine plays regardless of episode content.
const kSharedAudioIds = {
  'generic_fallback',
  'generic_too_long',
  'safety_tell_grownup',
};

class EpisodeFile {
  final File file;
  final Map<String, dynamic> raw;
  final EpisodeScript script;
  EpisodeFile(this.file, this.raw, this.script);

  String get fileId => file.uri.pathSegments.last.replaceAll('.json', '');
  String get folder => file.uri.pathSegments[file.uri.pathSegments.length - 2];

  /// Every audio id this episode can play.
  List<String> get audioIds => [
        for (final s in script.steps) ...[
          s.audio,
          if (s.onWrong != null) s.onWrong!,
          if (s.fallback != null) s.fallback!,
          ...s.intents.map((i) => i.audio),
        ]
      ];
}

List<EpisodeFile> loadEpisodeFiles() => [
      for (final f in Directory('assets/episodes')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.json')))
        () {
          final raw = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
          return EpisodeFile(f, raw, EpisodeScript.fromJson(raw));
        }()
    ];

/// line_id → text for docs/audio_script_{lang}.csv.
Map<String, String> loadAudioScript(String lang) =>
    loadAudioScriptColumn(lang, 'text_$lang');

/// line_id → [column] for docs/audio_script_{lang}.csv.
/// Minimal CSV reader: handles quoted fields containing commas and "".
Map<String, String> loadAudioScriptColumn(String lang, String column) {
  final lines = File('docs/audio_script_$lang.csv')
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .toList();
  final header = _parseCsvLine(lines.first);
  final textCol = header.indexOf(column);
  if (textCol == -1) throw StateError('no $column column in $lang script');
  return {
    for (final l in lines.skip(1))
      _parseCsvLine(l)[0]: _parseCsvLine(l)[textCol],
  };
}

List<String> _parseCsvLine(String line) {
  final out = <String>[];
  final buf = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (quoted) {
      if (c == '"' && i + 1 < line.length && line[i + 1] == '"') {
        buf.write('"');
        i++;
      } else if (c == '"') {
        quoted = false;
      } else {
        buf.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      out.add(buf.toString());
      buf.clear();
    } else {
      buf.write(c);
    }
  }
  out.add(buf.toString());
  return out;
}

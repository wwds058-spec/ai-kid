import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'models/episode_script.dart';

part 'episode_loader.g.dart';

/// Loads episode JSON from assets.
///
/// Asset path: assets/episodes/{world}/{episode_id}.json
/// e.g.       assets/episodes/pattern_forest/pf_ep01.json
class EpisodeLoader {
  Future<EpisodeScript> load(String episodeId) async {
    final world = _worldFromId(episodeId);
    final path = 'assets/episodes/$world/$episodeId.json';

    final raw = await rootBundle.loadString(path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return EpisodeScript.fromJson(json);
  }

  /// Derive world folder from episode id prefix.
  /// pf_  → pattern_forest
  /// ml_  → music_lab
  /// gc_  → gadget_city
  String _worldFromId(String id) {
    final prefix = id.split('_').first;
    const map = {
      'pf': 'pattern_forest',
      'ml': 'music_lab',
      'gc': 'gadget_city',
    };
    return map[prefix] ?? 'pattern_forest';
  }
}

@riverpod
EpisodeLoader episodeLoader(EpisodeLoaderRef ref) => EpisodeLoader();

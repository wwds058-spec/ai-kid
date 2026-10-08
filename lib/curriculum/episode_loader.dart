import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'episode_catalog.dart';
import 'models/episode_script.dart';

part 'episode_loader.g.dart';

/// Loads episode JSON from assets.
///
/// Asset path: assets/episodes/{world}/{episode_id}.json
/// e.g.       assets/episodes/pattern_forest/pf_ep01.json
class EpisodeLoader {
  Future<EpisodeScript> load(String episodeId) async {
    final world = EpisodeCatalog.worldOf(episodeId);
    if (world == null) {
      throw ArgumentError.value(episodeId, 'episodeId', 'not in a known world');
    }
    final path = 'assets/episodes/${world.id}/$episodeId.json';

    final raw = await rootBundle.loadString(path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return EpisodeScript.fromJson(json);
  }
}

@riverpod
EpisodeLoader episodeLoader(EpisodeLoaderRef ref) => EpisodeLoader();

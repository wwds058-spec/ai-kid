/// Play order of the episodes in each world.
///
/// Adding an episode = add its JSON under assets/episodes/{world}/ and its id
/// here; test/episode_content_test.dart fails if the two disagree.
class EpisodeCatalog {
  static const Map<String, List<String>> worlds = {
    'pattern_forest': ['pf_ep01', 'pf_ep02'],
  };

  static List<String> episodesIn(String world) => worlds[world] ?? const [];

  /// The episode after [episodeId] in its world, or null if it was the last.
  static String? next(String episodeId) {
    for (final list in worlds.values) {
      final i = list.indexOf(episodeId);
      if (i != -1) return i + 1 < list.length ? list[i + 1] : null;
    }
    return null;
  }

  /// Where tapping a world should start: its first unfinished episode, or the
  /// first episode again once all are done. Null if the world has no content.
  static String? resume(String world, Set<String> completed) {
    final list = episodesIn(world);
    if (list.isEmpty) return null;
    return list.firstWhere((id) => !completed.contains(id),
        orElse: () => list.first);
  }
}

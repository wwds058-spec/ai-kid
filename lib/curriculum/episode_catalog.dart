/// Single source of truth for which worlds and episodes exist, their play
/// order, and which episodes need Premium.
///
/// Adding an episode means: its JSON under assets/episodes/{world}/, a
/// [CatalogEpisode] here, and its audio lines in every language.
/// test/episode_content_test.dart fails if any of these disagree.
library;

/// Languages every episode must ship (titles, audio script, audio files).
const kLanguages = ['en', 'hi', 'te'];

class CatalogEpisode {
  final String id;

  /// Must equal the `premium` field in the episode JSON (checked by tests).
  final bool premium;

  const CatalogEpisode(this.id, {this.premium = false});
}

class CatalogWorld {
  /// Folder name under assets/episodes/.
  final String id;

  /// Every episode id in this world is `{prefix}_epNN`.
  final String prefix;
  final String emoji;
  final int color;
  final List<CatalogEpisode> episodes;

  const CatalogWorld({
    required this.id,
    required this.prefix,
    required this.emoji,
    required this.color,
    required this.episodes,
  });
}

enum WorldAccess { open, locked, comingSoon }

class EpisodeCatalog {
  static const worlds = <CatalogWorld>[
    CatalogWorld(
      id: 'pattern_forest',
      prefix: 'pf',
      emoji: '🌳',
      color: 0xFF059669,
      episodes: [CatalogEpisode('pf_ep01'), CatalogEpisode('pf_ep02')],
    ),
    CatalogWorld(
      id: 'music_lab',
      prefix: 'ml',
      emoji: '🎵',
      color: 0xFF7C3AED,
      episodes: [],
    ),
    CatalogWorld(
      id: 'gadget_city',
      prefix: 'gc',
      emoji: '⚙️',
      color: 0xFFD97706,
      episodes: [],
    ),
  ];

  static final _idPattern = RegExp(r'^([a-z]{2})_ep\d{2}$');

  /// The world an episode id belongs to, from its prefix (`pf_ep01` → pf).
  static CatalogWorld? worldOf(String episodeId) {
    final prefix = _idPattern.firstMatch(episodeId)?.group(1);
    for (final w in worlds) {
      if (w.prefix == prefix) return w;
    }
    return null;
  }

  static CatalogWorld? world(String worldId) {
    for (final w in worlds) {
      if (w.id == worldId) return w;
    }
    return null;
  }

  static CatalogEpisode? episode(String episodeId) {
    for (final e in worldOf(episodeId)?.episodes ?? const <CatalogEpisode>[]) {
      if (e.id == episodeId) return e;
    }
    return null;
  }

  static bool isValidId(String episodeId) => _idPattern.hasMatch(episodeId);

  /// Open if the child may play something here; locked if every episode
  /// needs Premium; coming soon if the world has no episodes yet.
  static WorldAccess access(CatalogWorld world, {required bool isPremium}) =>
      world.episodes.isEmpty
          ? WorldAccess.comingSoon
          : world.episodes.any((e) => canPlay(e, isPremium: isPremium))
              ? WorldAccess.open
              : WorldAccess.locked;

  static bool canPlay(CatalogEpisode e, {required bool isPremium}) =>
      !e.premium || isPremium;

  /// The episode after [episodeId] in its world, or null if it was the last.
  static CatalogEpisode? next(String episodeId) {
    final list = worldOf(episodeId)?.episodes ?? const <CatalogEpisode>[];
    final i = list.indexWhere((e) => e.id == episodeId);
    return i != -1 && i + 1 < list.length ? list[i + 1] : null;
  }

  /// Where tapping a world should start: its first unfinished episode the
  /// child may play, or the first playable one again once all are done.
  /// Null when nothing in the world is playable (empty, or all Premium).
  static String? resume(CatalogWorld world, Set<String> completed,
      {required bool isPremium}) {
    final playable = world.episodes
        .where((e) => canPlay(e, isPremium: isPremium))
        .toList();
    if (playable.isEmpty) return null;
    return playable
        .firstWhere((e) => !completed.contains(e.id),
            orElse: () => playable.first)
        .id;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/purchases/subscription_provider.dart';
import '../../curriculum/episode_catalog.dart';
import '../../curriculum/episode_controller.dart';
import '../../l10n/language.dart';
import '../../l10n/strings.dart';

/// World Map — choose a learning world.
///
/// Worlds come from [EpisodeCatalog]. A world is:
///  • open        — it has an episode this child may play
///  • locked      — it has episodes, but all of them need Premium
///  • coming soon — it has no episodes yet
/// The worlds shown on the map. Overridable in tests.
final catalogWorldsProvider =
    Provider<List<CatalogWorld>>((ref) => EpisodeCatalog.worlds);

class WorldMapScreen extends ConsumerWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final worlds = ref.watch(catalogWorldsProvider);
    return Scaffold(
      backgroundColor: AIExplorerTheme.offWhite,
      appBar: AppBar(
        title: Text(t.chooseWorld,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go(Routes.pinGate),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: worlds.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) =>
            _WorldCard(world: worlds[i]),
      ),
    );
  }
}

class _WorldCard extends ConsumerWidget {
  final CatalogWorld world;
  const _WorldCard({required this.world});

  /// Continue the world at its first unfinished playable episode.
  void _open(BuildContext context, WidgetRef ref, bool isPremium) {
    final completed = ref
        .read(hiveStorageServiceProvider)
        .allProgress()
        .where((p) => p.completed)
        .map((p) => p.episodeId)
        .toSet();
    final id = EpisodeCatalog.resume(world, completed, isPremium: isPremium);
    if (id != null) context.go(Routes.episodePath(id));
  }

  /// Locked worlds ask for a grown-up; purchases only happen in the
  /// PIN-protected parent dashboard, never from the child's screens.
  void _askGrownUp(BuildContext context, AppStrings t, String name) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${world.emoji} $name'),
        content: Text(t.worldLocked),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.ok),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(Routes.pinGate);
            },
            child: Text(t.forGrownUps),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final name = t.worldNames[world.id] ?? world.id;
    final color = Color(world.color);

    final access = EpisodeCatalog.access(world, isPremium: isPremium);
    final dimmed = access != WorldAccess.open;
    final badge = switch (access) {
      WorldAccess.locked => t.premium,
      WorldAccess.comingSoon => t.comingSoon,
      WorldAccess.open => null,
    };

    return GestureDetector(
      onTap: switch (access) {
        WorldAccess.open => () => _open(context, ref, isPremium),
        WorldAccess.locked => () => _askGrownUp(context, t, name),
        WorldAccess.comingSoon => null,
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: dimmed ? Colors.grey[100] : color.withOpacity(.1),
          border: Border.all(color: color.withOpacity(.4), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Text(world.emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: dimmed ? Colors.grey : color)),
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AIExplorerTheme.yellow.withOpacity(.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(badge,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: dimmed ? Colors.grey[300] : color, size: 18),
          ],
        ),
      ),
    );
  }
}

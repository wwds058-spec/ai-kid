import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../curriculum/episode_catalog.dart';
import '../../curriculum/episode_controller.dart';

/// World Map — choose a learning world.
/// Phase 1: shows Pattern Forest only (free).
/// Phase 2: unlock Music Lab, Gadget City with premium.
class WorldMapScreen extends StatelessWidget {
  const WorldMapScreen({super.key});

  static const _worlds = [
    _World(
      id: 'pf',
      name: 'Pattern Forest',
      emoji: '🌳',
      color: Color(0xFF059669),
      world: 'pattern_forest',
      premium: false,
    ),
    _World(
      id: 'ml',
      name: 'Music Lab',
      emoji: '🎵',
      color: Color(0xFF7C3AED),
      world: 'music_lab',
      premium: true,
    ),
    _World(
      id: 'gc',
      name: 'Gadget City',
      emoji: '⚙️',
      color: Color(0xFFD97706),
      world: 'gadget_city',
      premium: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AIExplorerTheme.offWhite,
      appBar: AppBar(
        title: const Text('Choose a World', style: TextStyle(fontWeight: FontWeight.w700)),
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
        itemCount: _worlds.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final world = _worlds[i];
          return _WorldCard(world: world);
        },
      ),
    );
  }
}

class _WorldCard extends ConsumerWidget {
  final _World world;
  const _WorldCard({required this.world});

  /// Continue the world at its first unfinished episode.
  void _open(BuildContext context, WidgetRef ref) {
    final completed = ref
        .read(hiveStorageServiceProvider)
        .allProgress()
        .where((p) => p.completed)
        .map((p) => p.episodeId)
        .toSet();
    final id = EpisodeCatalog.resume(world.world, completed);
    if (id != null) context.go(Routes.episodePath(id));
  }

  /// Locked worlds ask for a grown-up; purchases only happen in the
  /// PIN-protected parent dashboard, never from the child's screens.
  void _askGrownUp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${world.emoji} ${world.name}'),
        content: const Text('This world is part of Premium. '
            'Ask a grown-up to unlock it!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(Routes.pinGate);
            },
            child: const Text("I'm a grown-up"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref
        .read(hiveStorageServiceProvider)
        .getSubscription()
        .isActiveWithGrace;
    final hasContent = EpisodeCatalog.episodesIn(world.world).isNotEmpty;
    final locked = world.premium && !isPremium;
    final comingSoon = !locked && !hasContent;
    final dimmed = locked || comingSoon;
    final badge = locked ? '🔒 Premium' : (comingSoon ? '🌱 Coming soon' : null);

    return GestureDetector(
      onTap: locked
          ? () => _askGrownUp(context)
          : comingSoon
              ? null
              : () => _open(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: dimmed ? Colors.grey[100] : world.color.withOpacity(.1),
          border: Border.all(color: world.color.withOpacity(.4), width: 2),
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
                  Text(world.name,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: dimmed ? Colors.grey : world.color)),
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
                color: dimmed ? Colors.grey[300] : world.color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _World {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final String world;
  final bool premium;
  const _World({
    required this.id, required this.name, required this.emoji,
    required this.color, required this.world, required this.premium,
  });
}

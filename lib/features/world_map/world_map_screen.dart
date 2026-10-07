import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme.dart';

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
      firstEpisode: 'pf_ep01',
      premium: false,
    ),
    _World(
      id: 'ml',
      name: 'Music Lab',
      emoji: '🎵',
      color: Color(0xFF7C3AED),
      firstEpisode: 'ml_ep01',
      premium: true,
    ),
    _World(
      id: 'gc',
      name: 'Gadget City',
      emoji: '⚙️',
      color: Color(0xFFD97706),
      firstEpisode: 'gc_ep01',
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

class _WorldCard extends StatelessWidget {
  final _World world;
  const _WorldCard({required this.world});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: world.premium
          ? null
          : () => context.go(Routes.episodePath(world.firstEpisode)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: world.premium ? Colors.grey[100] : world.color.withOpacity(.1),
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
                          color: world.premium ? Colors.grey : world.color)),
                  if (world.premium)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AIExplorerTheme.yellow.withOpacity(.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('🔒 Premium',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: world.premium ? Colors.grey[300] : world.color, size: 18),
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
  final String firstEpisode;
  final bool premium;
  const _World({
    required this.id, required this.name, required this.emoji,
    required this.color, required this.firstEpisode, required this.premium,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme.dart';

/// Shown when a child completes an episode.
/// Displays earned badges with celebration animation.
class RewardScreen extends StatelessWidget {
  final String episodeId;
  final List<String> badges;

  const RewardScreen({super.key, required this.episodeId, required this.badges});

  // Badge id → display info
  static const _badgeMeta = <String, _BadgeMeta>{
    'pattern_spotter': _BadgeMeta('🔍', 'Pattern Spotter', 'You found the pattern!'),
    'ai_friend':       _BadgeMeta('🤝', 'AI Friend', 'You worked with Aiko!'),
    'data_collector':  _BadgeMeta('📊', 'Data Collector', 'You collected data!'),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 80))
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              const Text('Great job!',
                      style: TextStyle(
                          fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white))
                  .animate()
                  .fadeIn(delay: 300.ms),
              const SizedBox(height: 8),
              Text('You earned ${badges.length} badge${badges.length == 1 ? '' : 's'}!',
                      style: const TextStyle(fontSize: 18, color: Colors.white54))
                  .animate()
                  .fadeIn(delay: 500.ms),
              const SizedBox(height: 40),
              // Badge cards
              ...badges.asMap().entries.map((entry) {
                final meta = _badgeMeta[entry.value];
                if (meta == null) return const SizedBox.shrink();
                return _BadgeCard(meta: meta)
                    .animate()
                    .slideY(begin: .3, delay: Duration(milliseconds: 600 + entry.key * 150))
                    .fadeIn();
              }),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go(Routes.worldMap),
                child: const Text('Back to Worlds 🗺️'),
              ).animate().fadeIn(delay: 900.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final _BadgeMeta meta;
  const _BadgeCard({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AIExplorerTheme.purple.withOpacity(.15),
        border: Border.all(color: AIExplorerTheme.purple.withOpacity(.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(meta.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meta.name,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              Text(meta.description,
                  style: const TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeMeta {
  final String emoji, name, description;
  const _BadgeMeta(this.emoji, this.name, this.description);
}

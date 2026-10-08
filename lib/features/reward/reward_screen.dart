import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/purchases/subscription_provider.dart';
import '../../curriculum/badges.dart';
import '../../curriculum/episode_catalog.dart';
import '../../l10n/language.dart';

/// Shown when a child completes an episode.
/// Displays earned badges with celebration animation.
class RewardScreen extends ConsumerWidget {
  final String episodeId;
  final List<String> badges;

  const RewardScreen(
      {super.key, required this.episodeId, required this.badges});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final next = EpisodeCatalog.next(episodeId);
    final canPlayNext = next != null &&
        EpisodeCatalog.canPlay(next, isPremium: ref.watch(isPremiumProvider));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        // Scrolls when several badges (or longer Hindi/Telugu text) don't
        // fit; otherwise fills the screen with the buttons at the bottom.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 80))
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text(t.greatJob,
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white))
                        .animate()
                        .fadeIn(delay: 300.ms),
                    const SizedBox(height: 8),
                    Text(t.earnedBadges(badges.length),
                            style: const TextStyle(
                                fontSize: 18, color: Colors.white54))
                        .animate()
                        .fadeIn(delay: 500.ms),
                    const SizedBox(height: 40),
                    // Badge cards
                    ...badges.asMap().entries.map((entry) {
                      final emoji = kBadgeEmoji[entry.value];
                      final text = t.badges[entry.value];
                      if (emoji == null || text == null) {
                        return const SizedBox.shrink();
                      }
                      return _BadgeCard(
                              emoji: emoji,
                              name: text.name,
                              description: text.description)
                          .animate()
                          .slideY(
                              begin: .3,
                              delay:
                                  Duration(milliseconds: 600 + entry.key * 150))
                          .fadeIn();
                    }),
                    const Spacer(),
                    if (canPlayNext) ...[
                      ElevatedButton(
                        onPressed: () =>
                            context.go(Routes.episodePath(next.id)),
                        child: Text(t.nextAdventure),
                      ).animate().fadeIn(delay: 900.ms),
                      const SizedBox(height: 12),
                    ] else if (next != null) ...[
                      // Next episode is Premium: say so, but never sell to the child
                      Text(t.nextNeedsPremium,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                    ],
                    TextButton(
                      onPressed: () => context.go(Routes.worldMap),
                      child: Text(t.backToWorlds,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16)),
                    ).animate().fadeIn(delay: 900.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String emoji, name, description;
  const _BadgeCard(
      {required this.emoji, required this.name, required this.description});

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
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                Text(description,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

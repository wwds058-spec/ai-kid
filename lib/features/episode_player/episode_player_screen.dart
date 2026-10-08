import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/rive/aiko_widget.dart';
import '../../curriculum/episode_controller.dart';
import '../../curriculum/models/episode_state.dart';
import '../../curriculum/models/episode_script.dart';
import '../../l10n/language.dart';

/// The generic episode player.
/// Driven entirely by [EpisodeState] from [EpisodeController].
/// No episode-specific code here — the JSON is the source of truth.
class EpisodePlayerScreen extends ConsumerStatefulWidget {
  final String episodeId;
  const EpisodePlayerScreen({super.key, required this.episodeId});

  @override
  ConsumerState<EpisodePlayerScreen> createState() => _EpisodePlayerScreenState();
}

class _EpisodePlayerScreenState extends ConsumerState<EpisodePlayerScreen> {
  @override
  void initState() {
    super.initState();
    // Start the episode on next frame (controller must be built first)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(episodeControllerProvider(widget.episodeId).notifier)
          .start(lang: ref.read(languageProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(episodeControllerProvider(widget.episodeId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: state.when(
          loading: () => const _LoadingView(),
          running: (script, stepIndex, awaitingSpeech, awaitingTap, awaitingAnswer, lang) {
            final step = script.steps[stepIndex];
            // isTalking = not awaiting any interaction (audio is playing)
            final isTalking = !awaitingTap && !awaitingAnswer && !awaitingSpeech;
            return _RunningView(
              step: step,
              stepIndex: stepIndex,
              totalSteps: script.steps.length,
              awaitingTap: awaitingTap,
              awaitingAnswer: awaitingAnswer,
              awaitingSpeech: awaitingSpeech,
              isTalking: isTalking,
              onTap: () => ref
                  .read(episodeControllerProvider(widget.episodeId).notifier)
                  .handleTap(),
              onAnswer: (ans) => ref
                  .read(episodeControllerProvider(widget.episodeId).notifier)
                  .handleAnswer(ans),
            );
          },
          complete: (episodeId, badges) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(Routes.rewardPath(episodeId), extra: badges);
            });
            return const _LoadingView();
          },
          locked: () => const _LockedView(),
          error: (msg) {
            debugPrint('[EpisodePlayer] $msg');
            return const _ErrorView();
          },
        ),
      ),
    );
  }
}

// ── Sub-views ──────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AIExplorerTheme.purple),
      );
}

class _LockedView extends ConsumerWidget {
  const _LockedView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(t.episodeLocked,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(Routes.worldMap),
                child: Text(t.backToWorlds),
              ),
            ],
          ),
        ),
      );
  }
}

/// Friendly failure screen; the technical message goes to the debug log,
/// not to the child.
class _ErrorView extends ConsumerWidget {
  const _ErrorView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.loadError,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(Routes.worldMap),
              child: Text(t.backToWorlds),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunningView extends StatelessWidget {
  final EpisodeStep step;
  final int stepIndex;
  final int totalSteps;
  final bool awaitingTap;
  final bool awaitingAnswer;
  final bool awaitingSpeech;
  final bool isTalking;
  final VoidCallback onTap;
  final ValueChanged<String> onAnswer;

  const _RunningView({
    required this.step, required this.stepIndex, required this.totalSteps,
    required this.awaitingTap, required this.awaitingAnswer,
    required this.awaitingSpeech, required this.isTalking,
    required this.onTap, required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: awaitingTap ? onTap : null,
      child: Column(
        children: [
          // ── Progress bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: (stepIndex + 1) / totalSteps,
              backgroundColor: Colors.white12,
              color: AIExplorerTheme.purple,
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          // ── Scene / Aiko area ─────────────────────────────────────────────
          Expanded(
            child: Center(
              child: AikoWidget(
                emotion: step.emotion,
                isTalking: isTalking,
              ),
            ),
          ),

          // ── Step type indicator ──────────────────────────────────────────
          _StepIndicator(
            step: step,
            awaitingTap: awaitingTap,
            awaitingAnswer: awaitingAnswer,
            awaitingSpeech: awaitingSpeech,
            onAnswer: onAnswer,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}


class _StepIndicator extends ConsumerWidget {
  final EpisodeStep step;
  final bool awaitingTap, awaitingAnswer, awaitingSpeech;
  final ValueChanged<String> onAnswer;

  const _StepIndicator({
    required this.step, required this.awaitingTap,
    required this.awaitingAnswer, required this.awaitingSpeech,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    if (awaitingTap) {
      return _HintChip(label: t.tapToContinue);
    }
    if (awaitingSpeech) {
      return _HintChip(label: t.saySomething, highlight: true);
    }
    if (awaitingAnswer && step.gameConfig != null) {
      return _PatternGame(config: step.gameConfig!, onAnswer: onAnswer);
    }
    return const SizedBox.shrink();
  }
}

class _HintChip extends StatelessWidget {
  final String label;
  final bool highlight;
  const _HintChip({required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: highlight ? AIExplorerTheme.purple : Colors.white12,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center),
    );
  }
}

/// Simple pattern-tap game — show items, tap the missing one.
class _PatternGame extends StatelessWidget {
  final GameConfig config;
  final ValueChanged<String> onAnswer;

  const _PatternGame({required this.config, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    final items = config.items;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Pattern row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(item,
                          style: TextStyle(
                              fontSize: item == '❓' ? 36 : 28,
                              color: item == '❓' ? AIExplorerTheme.yellow : null)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          // Answer choices — unique non-? items
          Wrap(
            spacing: 12,
            children: items
                .where((i) => i != '❓')
                .toSet()
                .map((choice) => GestureDetector(
                      onTap: () => onAnswer(choice),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(choice,
                              style: const TextStyle(fontSize: 32)),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

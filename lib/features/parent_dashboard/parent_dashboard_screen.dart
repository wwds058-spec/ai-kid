import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/purchases/purchase_service.dart';
import '../../curriculum/episode_controller.dart';

/// Parent Dashboard — protected by PIN in Phase 2.
/// Phase 1: stub showing basic stats and settings toggles.
class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(hiveStorageServiceProvider);
    final settings = storage.getSettings();
    final progress = storage.allProgress();
    final sub = storage.getSubscription();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AIExplorerTheme.purple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.worldMap),
          // Parent dashboard only reached after PIN — go back to world map
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Stats ──────────────────────────────────────────────────────
          _SectionTitle('Progress'),
          _StatRow('Episodes completed',
              '${progress.where((p) => p.completed).length}'),
          _StatRow('Total badges earned',
              '${progress.expand((p) => p.badgesEarned).length}'),
          _StatRow('Disclosure events',
              '${settings.disclosureLog.length}'),

          const SizedBox(height: 24),
          // ── Subscription ───────────────────────────────────────────────
          _SectionTitle('Subscription'),
          _StatRow('Status', sub.isPremium ? '✅ Premium' : '🔓 Free'),
          if (sub.expiresAt != null)
            _StatRow('Expires', sub.expiresAt!.toLocal().toString().split(' ').first),

          const SizedBox(height: 24),
          // ── Settings (toggles — Phase 1 read-only) ────────────────────
          _SectionTitle('Settings'),
          _SettingRow(
            label: 'Voice interaction',
            value: settings.voiceEnabled,
            onChanged: (v) {
              storage.saveSettings(settings.copyWith(voiceEnabled: v));
            },
          ),
          _SettingRow(
            label: 'AI interaction enabled',
            value: settings.aiInteractionEnabled,
            onChanged: (v) {
              storage.saveSettings(settings.copyWith(aiInteractionEnabled: v));
            },
          ),
          _StatRow('Daily limit', '${settings.dailyLimitMinutes} minutes'),

          const SizedBox(height: 32),
          if (!sub.isPremium)
            ElevatedButton(
              onPressed: () async {
                final svc = ref.read(purchaseServiceProvider);
                final offerings = await svc.fetchOfferings();
                final pkg = offerings?.current?.annual;
                if (pkg == null) return;
                await svc.purchase(pkg);
              },
              child: const Text('Upgrade to Premium'),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final restored =
                  await ref.read(purchaseServiceProvider).restorePurchases();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      restored ? '✅ Premium restored!' : 'No purchases found.'),
                ));
              }
            },
            child: const Text('Restore Purchases'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: .08,
                color: Colors.grey)),
      );
}

class _StatRow extends StatelessWidget {
  final String label, value;
  const _StatRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: AIExplorerTheme.purple)),
          ],
        ),
      );
}

class _SettingRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingRow({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
        activeColor: AIExplorerTheme.purple,
        contentPadding: EdgeInsets.zero,
      );
}

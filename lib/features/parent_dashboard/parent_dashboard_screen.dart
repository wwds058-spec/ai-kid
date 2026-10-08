import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/purchases/purchase_service.dart';
import '../../core/purchases/subscription_provider.dart';
import '../../core/security/parent_gate.dart';
import '../../curriculum/episode_catalog.dart';
import '../../curriculum/episode_controller.dart';
import '../../l10n/language.dart';
import '../../l10n/strings.dart';

/// Parent Dashboard — protected by PIN in Phase 2.
/// Phase 1: stub showing basic stats and settings toggles.
class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  bool _busy = false;

  static const _purchaseMessages = {
    PurchaseResult.unlocked: '✅ Premium unlocked!',
    PurchaseResult.cancelled: 'Purchase cancelled.',
    PurchaseResult.notEntitled:
        'The store accepted the payment but Premium did not activate. '
            'Try "Restore Purchases".',
    PurchaseResult.unavailable:
        "Purchases aren't available right now. Check your connection.",
    PurchaseResult.failed: 'Purchase failed. Please try again.',
  };

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    final message = await action();
    // PurchaseService has written the new entitlement; publish it so the
    // world map and episodes unlock immediately.
    ref.read(subscriptionProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String> _upgrade() async =>
      _purchaseMessages[await ref.read(purchaseServiceProvider).buyAnnual()]!;

  Future<String> _restore() async =>
      await ref.read(purchaseServiceProvider).restorePurchases()
          ? '✅ Premium restored!'
          : 'No purchases found.';

  @override
  Widget build(BuildContext context) {
    final storage = ref.read(hiveStorageServiceProvider);
    final settings = storage.getSettings();
    final progress = storage.allProgress();
    final sub = ref.watch(subscriptionProvider);
    final lang = ref.watch(languageProvider);
    final inGrace = sub.isActiveWithGrace &&
        sub.expiresAt != null &&
        DateTime.now().isAfter(sub.expiresAt!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AIExplorerTheme.purple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Re-lock on the way out so the next visit needs the PIN again
          onPressed: () {
            ref.read(parentGateProvider).lock();
            context.go(Routes.worldMap);
          },
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
          _StatRow(
              'Status',
              !sub.isActiveWithGrace
                  ? '🔓 Free'
                  : inGrace
                      ? '⚠️ Premium (expired, grace period)'
                      : '✅ Premium'),
          if (sub.expiresAt != null)
            _StatRow('Expires', sub.expiresAt!.toLocal().toString().split(' ').first),

          const SizedBox(height: 24),
          // ── Settings (toggles — Phase 1 read-only) ────────────────────
          _SectionTitle('Settings'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Language', style: TextStyle(fontSize: 15)),
              DropdownButton<String>(
                key: const ValueKey('language_dropdown'),
                value: lang,
                items: [
                  for (final code in kLanguages)
                    DropdownMenuItem(
                        value: code, child: Text(AppStrings.nativeNames[code]!)),
                ],
                onChanged: (code) {
                  if (code != null) ref.read(languageProvider.notifier).set(code);
                },
              ),
            ],
          ),
          _SettingRow(
            label: 'Voice interaction',
            value: settings.voiceEnabled,
            onChanged: (v) {
              storage.saveSettings(settings.copyWith(voiceEnabled: v));
              setState(() {});
            },
          ),
          _SettingRow(
            label: 'AI interaction enabled',
            value: settings.aiInteractionEnabled,
            onChanged: (v) {
              storage.saveSettings(settings.copyWith(aiInteractionEnabled: v));
              setState(() {});
            },
          ),
          _StatRow('Daily limit', '${settings.dailyLimitMinutes} minutes'),

          const SizedBox(height: 32),
          if (!sub.isActiveWithGrace || inGrace)
            ElevatedButton(
              onPressed: _busy ? null : () => _run(_upgrade),
              child: Text(inGrace ? 'Renew Premium' : 'Upgrade to Premium'),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : () => _run(_restore),
            child: const Text('Restore Purchases'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
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
            Flexible(child: Text(label, style: const TextStyle(fontSize: 16))),
            const SizedBox(width: 12),
            // Long values (e.g. the grace-period status) wrap instead of
            // overflowing on narrow phones or with large accessibility text.
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: AIExplorerTheme.purple)),
            ),
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

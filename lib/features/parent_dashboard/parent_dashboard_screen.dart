import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/feature_flags.dart';
import '../../core/purchases/purchase_service.dart';
import '../../core/purchases/subscription_provider.dart';
import '../../core/security/parent_gate.dart';
import '../../core/storage/models/subscription_state.dart';
import '../../curriculum/episode_catalog.dart';
import '../../curriculum/episode_controller.dart';
import '../../l10n/language.dart';
import '../../l10n/parent_strings.dart';
import '../../l10n/strings.dart';

/// Parent Dashboard — reached only through the PIN gate.
/// All text comes from [ParentStrings] (English for now).
class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  bool _busy = false;

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    final message = await action();
    // PurchaseService has written the new entitlement; publish it so the
    // world map and episodes update immediately.
    ref.read(subscriptionProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String> _upgrade(ParentStrings p) async =>
      switch (await ref.read(purchaseServiceProvider).buyAnnual()) {
        PurchaseResult.unlocked => p.purchaseUnlocked,
        PurchaseResult.cancelled => p.purchaseCancelled,
        PurchaseResult.notEntitled => p.purchaseNotEntitled,
        PurchaseResult.unavailable => p.purchaseUnavailable,
        PurchaseResult.failed => p.purchaseFailed,
      };

  Future<String> _restore(ParentStrings p) async =>
      switch (await ref.read(purchaseServiceProvider).restorePurchases()) {
        RestoreResult.found => p.restoreFound,
        RestoreResult.nothingFound => p.restoreNothing,
        RestoreResult.unavailable => p.restoreUnavailable,
      };

  static String _date(DateTime d) => d.toLocal().toString().split(' ').first;

  static String statusText(SubscriptionState sub, ParentStrings p, DateTime now) =>
      ParentDashboardScreenStatus.text(sub, p, now);

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(parentStringsProvider);
    final storage = ref.read(hiveStorageServiceProvider);
    final settings = storage.getSettings();
    final progress = storage.allProgress();
    final sub = ref.watch(subscriptionProvider);
    final lang = ref.watch(languageProvider);
    final now = DateTime.now();
    final storeReady = ref.read(purchaseServiceProvider).isConfigured;
    final flags = ref.watch(featureFlagsProvider);
    final inGrace = sub.isActiveWithGrace &&
        sub.expiresAt != null &&
        now.isAfter(sub.expiresAt!);
    final offerPurchase = !sub.isActiveWithGrace || inGrace;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.dashboardTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
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
          // ── Progress ───────────────────────────────────────────────────
          _SectionTitle(p.progress),
          _StatRow(p.episodesCompleted,
              '${progress.where((e) => e.completed).length}'),
          _StatRow(p.badgesEarned,
              '${progress.expand((e) => e.badgesEarned).length}'),
          _StatRow(p.safetyEvents, '${settings.disclosureLog.length}'),

          const SizedBox(height: 24),
          // ── Subscription ───────────────────────────────────────────────
          _SectionTitle(p.subscription),
          _StatRow(p.status, statusText(sub, p, now)),
          if (sub.isActiveWithGrace && sub.expiresAt != null)
            _StatRow('',
                sub.willRenew ? p.expires(_date(sub.expiresAt!)) : p.premiumUntil(_date(sub.expiresAt!))),
          if (!storeReady)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(p.storeNotConfigured,
                  style: const TextStyle(color: Colors.grey)),
            ),

          const SizedBox(height: 24),
          // ── Settings ───────────────────────────────────────────────────
          _SectionTitle(p.settings),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(p.language, style: const TextStyle(fontSize: 15))),
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
          SwitchListTile(
            key: const ValueKey('voice_switch'),
            title: Text(p.voice),
            subtitle: Text(p.voiceHelp),
            value: settings.voiceEnabled,
            activeColor: AIExplorerTheme.purple,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) async {
              await storage.saveSettings(settings.copyWith(voiceEnabled: v));
              setState(() {});
            },
          ),
          // Feature-gated: model + storage exist, behaviour not shipped yet.
          if (flags.dailyLimit)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(p.dailyLimit, style: const TextStyle(fontSize: 15))),
                DropdownButton<int>(
                  key: const ValueKey('daily_limit_dropdown'),
                  value: settings.dailyLimitMinutes,
                  items: [
                    for (final m in {15, 30, 45, 60, settings.dailyLimitMinutes})
                      DropdownMenuItem(value: m, child: Text(p.minutes(m))),
                  ],
                  onChanged: (m) async {
                    if (m == null) return;
                    await storage.saveSettings(settings.copyWith(dailyLimitMinutes: m));
                    setState(() {});
                  },
                ),
              ],
            ),
          if (flags.aiInteraction)
            SwitchListTile(
              key: const ValueKey('ai_interaction_switch'),
              title: Text(p.aiInteraction),
              subtitle: Text(p.aiInteractionHelp),
              value: settings.aiInteractionEnabled,
              activeColor: AIExplorerTheme.purple,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) async {
                await storage.saveSettings(settings.copyWith(aiInteractionEnabled: v));
                setState(() {});
              },
            ),

          const SizedBox(height: 32),
          if (offerPurchase)
            ElevatedButton(
              onPressed: _busy ? null : () => _run(() => _upgrade(p)),
              child: Text(inGrace ? p.renew : p.upgrade),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : () => _run(() => _restore(p)),
            child: Text(p.restore),
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

/// Subscription status line for the parent dashboard.
abstract final class ParentDashboardScreenStatus {
  static String text(SubscriptionState sub, ParentStrings p, DateTime now) {
    if (!sub.isActiveWithGrace) return p.statusFree;
    if (sub.expiresAt != null && now.isAfter(sub.expiresAt!)) return p.statusGrace;
    if (sub.billingIssue) return p.statusBillingIssue;
    if (!sub.willRenew) return p.statusCancelled;
    return p.statusPremium;
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/language.dart';

/// Privacy policy, bundled with the app so parents can read it offline.
/// Source: assets/legal/privacy_policy_en.md (also the text to host for the
/// Play listing's privacy-policy URL).
class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  static const asset = 'assets/legal/privacy_policy_en.md';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(parentStringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(p.privacyPolicy),
        backgroundColor: AIExplorerTheme.purple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(asset),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SelectableText(_plain(snap.data!),
                style: const TextStyle(fontSize: 15, height: 1.45)),
          );
        },
      ),
    );
  }

  /// Light Markdown cleanup for display: headings and bold markers removed.
  static String _plain(String md) => md
      .split('\n')
      .map((l) => l.replaceFirst(RegExp(r'^#+\s*'), ''))
      .join('\n')
      .replaceAll('**', '')
      .replaceAll('_', '');
}

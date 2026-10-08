import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../curriculum/episode_catalog.dart';
import '../../l10n/language.dart';
import '../../l10n/strings.dart';

/// Onboarding — greet the child and pick the language Aiko speaks.
/// The choice is saved in the child's profile and can be changed later
/// from the parent dashboard.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AIExplorerTheme.purpleSoft,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            children: [
              // Placeholder for Aiko Rive character
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AIExplorerTheme.purple.withOpacity(.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 72)),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                t.greeting,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                t.tagline,
                style: TextStyle(fontSize: 17, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Language picker — each option in its own script
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (final code in kLanguages)
                    ChoiceChip(
                      key: ValueKey('lang_$code'),
                      label: Text(AppStrings.nativeNames[code]!,
                          style: const TextStyle(fontSize: 18)),
                      selected: lang == code,
                      onSelected: (_) =>
                          ref.read(languageProvider.notifier).set(code),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go(Routes.worldMap),
                child: Text(t.letsGo),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(Routes.pinGate),
                child: Text(
                  t.parentSettings,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

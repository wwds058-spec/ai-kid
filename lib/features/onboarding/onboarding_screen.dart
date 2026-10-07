import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme.dart';

/// Onboarding — collect child's name + language preference.
/// Phase 1: stub that goes straight to World Map.
/// Phase 2: add avatar picker, Aiko animation, parent PIN setup.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AIExplorerTheme.purpleSoft,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              const Text(
                "Hi! I'm Aiko 👋",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'I\'ll teach you all about AI — let\'s explore together!',
                style: TextStyle(fontSize: 17, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.go(Routes.worldMap),
                child: const Text("Let's Go! 🚀"),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(Routes.pinGate),
                child: Text(
                  'Parent / Settings',
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

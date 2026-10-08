import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/audio/audio_service.dart';
import 'core/purchases/subscription_provider.dart';
import 'core/security/monotonic_clock.dart';
import 'core/storage/hive_storage_service.dart';

/// RevenueCat public Android SDK key, supplied at build time:
///   flutter build appbundle --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
/// Without it the app runs with purchases unavailable (free content only).
const _kRevenueCatKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — children's apps don't need landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Storage first: the cached entitlement lets the app start offline.
  await HiveStorageService.init();

  // Spoken-content audio session; follows calls/alarms/other apps.
  final audio = AudioService();
  try {
    await audio.init();
  } catch (_) {
    // Audio session unavailable (rare): playback still works without it.
  }

  // Tamper-proof clock for the parent-PIN lockout.
  final clock = await PlatformMonotonicClock.create();

  final container = ProviderContainer(overrides: [
    monotonicClockProvider.overrideWithValue(clock),
    audioServiceProvider.overrideWithValue(audio),
  ]);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SubscriptionLifecycle(child: AIExplorerApp()),
    ),
  );

  // Verify the entitlement in the background; launch never waits on the
  // network. The cached value (with grace) applies until this completes.
  unawaited(container.read(subscriptionProvider.notifier).start(_kRevenueCatKey));
}

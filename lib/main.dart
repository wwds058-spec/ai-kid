import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/purchases/purchase_service.dart';
import 'core/storage/hive_storage_service.dart';

/// Replace with your RevenueCat PUBLIC SDK key.
/// Found at app.revenuecat.com → Project → API keys → Public app-specific key.
const _kRevenueCatKey = 'YOUR_REVENUECAT_PUBLIC_SDK_KEY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — children's apps don't need landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialise Hive before RevenueCat so storage is ready for subscription sync
  final storage = HiveStorageService();
  await HiveStorageService.init();

  // Configure RevenueCat and sync entitlement to Hive immediately.
  // If offline, the previous Hive value is kept (3-day grace period applies).
  await PurchaseService.configure(
    apiKey: _kRevenueCatKey,
    storage: storage,
  );

  runApp(
    // ProviderScope is the root for all Riverpod providers
    const ProviderScope(
      child: AIExplorerApp(),
    ),
  );
}

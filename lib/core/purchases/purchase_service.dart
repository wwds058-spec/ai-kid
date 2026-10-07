import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/hive_storage_service.dart';
import '../storage/models/subscription_state.dart';

part 'purchase_service.g.dart';

/// Wraps RevenueCat and keeps [SubscriptionState] in Hive in sync.
///
/// Call [PurchaseService.configure] once in main() AFTER HiveStorageService.init().
/// Then use [purchaseServiceProvider] throughout the app.
class PurchaseService {
  PurchaseService._();

  // ─────────────────────────────────────────────────────────────────────────
  // Static init — called once in main()
  // ─────────────────────────────────────────────────────────────────────────

  /// Configure RevenueCat SDK and sync the current entitlement to Hive.
  ///
  /// [apiKey]  — public SDK key from app.revenuecat.com
  /// [storage] — already-initialised HiveStorageService
  static Future<void> configure({
    required String apiKey,
    required HiveStorageService storage,
  }) async {
    await Purchases.setLogLevel(LogLevel.error);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    // Sync immediately so the app has fresh entitlement on launch
    await _syncToHive(storage);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Instance — injected via Riverpod after configure() has run
  // ─────────────────────────────────────────────────────────────────────────

  final _storage = HiveStorageService();

  /// Restore purchases (called from Parent Dashboard).
  /// Returns true if a premium entitlement was found.
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return _applyCustomerInfo(info);
    } catch (_) {
      return false;
    }
  }

  /// Purchase a product by its RevenueCat package.
  /// Returns true on success.
  Future<bool> purchase(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      return _applyCustomerInfo(info);
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    }
  }

  /// Fetch available offerings from RevenueCat.
  Future<Offerings?> fetchOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  bool _applyCustomerInfo(CustomerInfo info) {
    final isPremium = info.entitlements.active.containsKey('premium');
    final expiresAt = isPremium
        ? DateTime.tryParse(
            info.entitlements.active['premium']?.expirationDate ?? '')
        : null;
    final productId =
        info.entitlements.active['premium']?.productIdentifier;

    _storage.saveSubscription(
      SubscriptionState(
        isPremium: isPremium,
        expiresAt: expiresAt,
        productId: productId,
        lastVerifiedAt: DateTime.now(),
      ),
    );
    return isPremium;
  }

  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> _syncToHive(HiveStorageService storage) async {
    try {
      final info = await Purchases.getCustomerInfo();
      final isPremium = info.entitlements.active.containsKey('premium');
      final expiresAt = isPremium
          ? DateTime.tryParse(
              info.entitlements.active['premium']?.expirationDate ?? '')
          : null;
      final productId =
          info.entitlements.active['premium']?.productIdentifier;

      await storage.saveSubscription(
        SubscriptionState(
          isPremium: isPremium,
          expiresAt: expiresAt,
          productId: productId,
          lastVerifiedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // Network unavailable — keep previous Hive value (grace period covers this)
    }
  }
}

@riverpod
PurchaseService purchaseService(Ref ref) => PurchaseService._();

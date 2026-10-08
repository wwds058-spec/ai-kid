import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/hive_storage_service.dart';
import '../storage/models/subscription_state.dart';

part 'purchase_service.g.dart';

/// What happened when a parent tried to buy Premium.
enum PurchaseResult {
  /// Store charged and the 'premium' entitlement is now active.
  unlocked,
  /// Parent closed the store sheet.
  cancelled,
  /// Store reported success but no 'premium' entitlement came back
  /// (usually a RevenueCat product/entitlement misconfiguration).
  notEntitled,
  /// No offering/package to sell (offline, or none configured).
  unavailable,
  /// Any other store error.
  failed,
}

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
      return await _applyCustomerInfo(info);
    } catch (_) {
      return false;
    }
  }

  /// Buy the current offering's annual package. Never throws.
  Future<PurchaseResult> buyAnnual() async {
    final package = (await fetchOfferings())?.current?.annual;
    if (package == null) return PurchaseResult.unavailable;
    try {
      final info = await Purchases.purchasePackage(package);
      return await _applyCustomerInfo(info)
          ? PurchaseResult.unlocked
          : PurchaseResult.notEntitled;
    } on PlatformException catch (e) {
      return PurchasesErrorHelper.getErrorCode(e) ==
              PurchasesErrorCode.purchaseCancelledError
          ? PurchaseResult.cancelled
          : PurchaseResult.failed;
    } catch (_) {
      return PurchaseResult.failed;
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

  Future<bool> _applyCustomerInfo(CustomerInfo info) async {
    final isPremium = info.entitlements.active.containsKey('premium');
    final expiresAt = isPremium
        ? DateTime.tryParse(
            info.entitlements.active['premium']?.expirationDate ?? '')
        : null;
    final productId =
        info.entitlements.active['premium']?.productIdentifier;

    await _storage.saveSubscription(
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../curriculum/episode_controller.dart';
import '../storage/hive_storage_service.dart';
import '../storage/models/subscription_state.dart';
import 'store_client.dart';

export 'store_client.dart' show EntitlementSnapshot, StoreClient;

/// What happened when a parent tried to buy Premium.
enum PurchaseResult {
  /// Store charged and the Premium entitlement is now active.
  unlocked,
  /// Parent closed the store sheet.
  cancelled,
  /// Store reported success but no Premium entitlement came back
  /// (usually a RevenueCat product/entitlement misconfiguration).
  notEntitled,
  /// No store, no offering, no network, or no API key in this build.
  unavailable,
  /// Any other store error.
  failed,
}

enum RestoreResult { found, nothingFound, unavailable }

enum SyncResult {
  /// Store answered; the cache now matches it.
  verified,
  /// Store unreachable; the cached entitlement (with grace) still applies.
  offline,
  /// No API key in this build; nothing to sync.
  notConfigured,
}

/// Premium entitlement rules. The store (RevenueCat) is the source of truth;
/// [HiveStorageService] caches its last answer so the app works offline.
///
///  • active               → Premium until expiresAt
///  • active, !willRenew   → cancelled by the parent; Premium until expiresAt
///  • active, billingIssue → Play's payment grace; still Premium, parent told
///  • inactive             → expired, refunded or revoked: locked at once
///  • store unreachable    → keep the cache; SubscriptionState allows 3 days
///                           past expiresAt before locking
class PurchaseService {
  PurchaseService({required this.storage, required this.client});

  final HiveStorageService storage;
  final StoreClient client;
  bool _configured = false;

  bool get isConfigured => _configured;

  /// Configure the store. An empty [apiKey] (no --dart-define) leaves
  /// purchases unavailable instead of crashing.
  Future<void> init(String apiKey,
      {void Function()? onEntitlementChanged}) async {
    if (apiKey.isEmpty || _configured) return;
    try {
      await client.configure(apiKey);
      _configured = true;
      client.onChange((snap) async {
        await _save(snap);
        onEntitlementChanged?.call();
      });
    } catch (_) {
      _configured = false;
    }
  }

  Future<SyncResult> sync() async {
    if (!_configured) return SyncResult.notConfigured;
    try {
      await _save(await client.fetch());
      return SyncResult.verified;
    } on StoreException {
      return SyncResult.offline;
    }
  }

  /// Buy the current offering's annual package. Never throws.
  Future<PurchaseResult> buyAnnual() async {
    if (!_configured) return PurchaseResult.unavailable;
    try {
      final snap = await client.buyAnnual();
      await _save(snap);
      return snap.active ? PurchaseResult.unlocked : PurchaseResult.notEntitled;
    } on StoreException catch (e) {
      return switch (e.kind) {
        StoreErrorKind.cancelled => PurchaseResult.cancelled,
        StoreErrorKind.unavailable => PurchaseResult.unavailable,
        StoreErrorKind.failed => PurchaseResult.failed,
      };
    }
  }

  /// Restore purchases (parent dashboard). Never throws.
  Future<RestoreResult> restorePurchases() async {
    if (!_configured) return RestoreResult.unavailable;
    try {
      final snap = await client.restore();
      await _save(snap);
      return snap.active ? RestoreResult.found : RestoreResult.nothingFound;
    } on StoreException {
      return RestoreResult.unavailable;
    }
  }

  Future<void> _save(EntitlementSnapshot snap) =>
      storage.saveSubscription(stateFrom(snap, DateTime.now()));

  static SubscriptionState stateFrom(EntitlementSnapshot snap, DateTime now) =>
      snap.active
          ? SubscriptionState(
              isPremium: true,
              expiresAt: snap.expiresAt,
              productId: snap.productId,
              willRenew: snap.willRenew,
              billingIssue: snap.billingIssue,
              lastVerifiedAt: now,
            )
          : SubscriptionState(lastVerifiedAt: now);
}

final storeClientProvider =
    Provider<StoreClient>((ref) => RevenueCatStoreClient());

final purchaseServiceProvider = Provider<PurchaseService>((ref) =>
    PurchaseService(
        storage: ref.read(hiveStorageServiceProvider),
        client: ref.read(storeClientProvider)));

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat entitlement that unlocks Premium content.
const kPremiumEntitlement = 'premium';

/// The store's view of the Premium entitlement at one moment.
class EntitlementSnapshot {
  final bool active;
  final DateTime? expiresAt;
  final String? productId;
  final bool willRenew;
  final bool billingIssue;

  const EntitlementSnapshot({
    required this.active,
    this.expiresAt,
    this.productId,
    this.willRenew = true,
    this.billingIssue = false,
  });

  const EntitlementSnapshot.inactive() : this(active: false);
}

enum StoreErrorKind { cancelled, unavailable, failed }

class StoreException implements Exception {
  final StoreErrorKind kind;
  final String? message;
  const StoreException(this.kind, [this.message]);
  @override
  String toString() => 'StoreException($kind, $message)';
}

/// Everything the app needs from the billing store. [RevenueCatStoreClient]
/// is the real one; tests use a fake so every rule in PurchaseService is
/// exercised without Google Play.
abstract class StoreClient {
  Future<void> configure(String apiKey);
  Future<EntitlementSnapshot> fetch();
  Future<EntitlementSnapshot> buyAnnual();
  Future<EntitlementSnapshot> restore();
  void onChange(void Function(EntitlementSnapshot) listener);
}

/// Thin adapter over the RevenueCat SDK. Holds no business rules.
class RevenueCatStoreClient implements StoreClient {
  @override
  Future<void> configure(String apiKey) async {
    await Purchases.setLogLevel(LogLevel.error);
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  @override
  Future<EntitlementSnapshot> fetch() =>
      _guard(() async => _snapshot(await Purchases.getCustomerInfo()));

  @override
  Future<EntitlementSnapshot> buyAnnual() => _guard(() async {
        final package = (await Purchases.getOfferings()).current?.annual;
        if (package == null) {
          throw const StoreException(
              StoreErrorKind.unavailable, 'no current annual package');
        }
        return _snapshot(
            (await Purchases.purchase(PurchaseParams.package(package))).customerInfo);
      });

  @override
  Future<EntitlementSnapshot> restore() =>
      _guard(() async => _snapshot(await Purchases.restorePurchases()));

  @override
  void onChange(void Function(EntitlementSnapshot) listener) =>
      Purchases.addCustomerInfoUpdateListener((info) => listener(_snapshot(info)));

  static EntitlementSnapshot _snapshot(CustomerInfo info) {
    final e = info.entitlements.active[kPremiumEntitlement];
    if (e == null || !e.isActive) return const EntitlementSnapshot.inactive();
    return EntitlementSnapshot(
      active: true,
      expiresAt: DateTime.tryParse(e.expirationDate ?? ''),
      productId: e.productIdentifier,
      willRenew: e.willRenew,
      billingIssue: e.billingIssueDetectedAt != null,
    );
  }

  static Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on StoreException {
      rethrow;
    } on PlatformException catch (e) {
      throw StoreException(_kind(PurchasesErrorHelper.getErrorCode(e)), e.message);
    } catch (e) {
      throw StoreException(StoreErrorKind.failed, '$e');
    }
  }

  static StoreErrorKind _kind(PurchasesErrorCode code) => switch (code) {
        PurchasesErrorCode.purchaseCancelledError => StoreErrorKind.cancelled,
        PurchasesErrorCode.networkError ||
        PurchasesErrorCode.offlineConnectionError ||
        PurchasesErrorCode.storeProblemError ||
        PurchasesErrorCode.productNotAvailableForPurchaseError ||
        PurchasesErrorCode.configurationError =>
          StoreErrorKind.unavailable,
        _ => StoreErrorKind.failed,
      };
}

import 'package:ai_explorer/core/purchases/store_client.dart';

/// Scriptable stand-in for RevenueCat/Google Play.
class FakeStore implements StoreClient {
  /// What fetch/restore report as the current entitlement.
  EntitlementSnapshot current = const EntitlementSnapshot.inactive();

  /// What a purchase returns (null = becomes [premiumSnapshot]).
  EntitlementSnapshot? purchaseResult;

  /// Thrown by the next call of the named operation, then cleared.
  StoreException? failFetch, failBuy, failRestore, failConfigure;

  int fetches = 0, purchases = 0, restores = 0;
  String? configuredWith;
  void Function(EntitlementSnapshot)? _listener;

  static final premiumSnapshot = EntitlementSnapshot(
    active: true,
    expiresAt: DateTime.now().add(const Duration(days: 365)),
    productId: 'ai_explorer_annual',
  );

  /// Simulate Google Play/RevenueCat pushing a change (renewal, cancel, refund).
  void push(EntitlementSnapshot snap) {
    current = snap;
    _listener?.call(snap);
  }

  @override
  Future<void> configure(String apiKey) async {
    final f = failConfigure;
    failConfigure = null;
    if (f != null) throw f;
    configuredWith = apiKey;
  }

  @override
  Future<EntitlementSnapshot> fetch() async {
    fetches++;
    final f = failFetch;
    failFetch = null;
    if (f != null) throw f;
    return current;
  }

  @override
  Future<EntitlementSnapshot> buyAnnual() async {
    purchases++;
    final f = failBuy;
    failBuy = null;
    if (f != null) throw f;
    current = purchaseResult ?? premiumSnapshot;
    return current;
  }

  @override
  Future<EntitlementSnapshot> restore() async {
    restores++;
    final f = failRestore;
    failRestore = null;
    if (f != null) throw f;
    return current;
  }

  @override
  void onChange(void Function(EntitlementSnapshot) listener) =>
      _listener = listener;
}

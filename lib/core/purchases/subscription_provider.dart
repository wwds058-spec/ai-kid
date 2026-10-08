import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../curriculum/episode_controller.dart';
import '../storage/models/subscription_state.dart';
import 'purchase_service.dart';

/// Live view of the cached entitlement. Screens watch this, so a purchase,
/// restore, renewal or cancellation shows up without a restart.
class SubscriptionNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() =>
      ref.read(hiveStorageServiceProvider).getSubscription();

  /// Re-read after PurchaseService has written a new entitlement.
  void refresh() =>
      state = ref.read(hiveStorageServiceProvider).getSubscription();

  /// Configure the store and verify the entitlement. Never blocks launch on
  /// the network: call without awaiting.
  Future<SyncResult> start(String apiKey) async {
    final service = ref.read(purchaseServiceProvider);
    await service.init(apiKey, onEntitlementChanged: refresh);
    return sync();
  }

  /// Ask the store for the current entitlement (on launch and every resume).
  Future<SyncResult> sync() async {
    final result = await ref.read(purchaseServiceProvider).sync();
    refresh();
    return result;
  }
}

final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionState>(
        SubscriptionNotifier.new);

/// True while Premium content may be played (includes the 3-day offline grace).
final isPremiumProvider =
    Provider<bool>((ref) => ref.watch(subscriptionProvider).isActiveWithGrace);

/// Re-verifies the entitlement whenever the app returns to the foreground,
/// so renewals, cancellations and refunds made in Google Play apply promptly.
class SubscriptionLifecycle extends ConsumerStatefulWidget {
  const SubscriptionLifecycle({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SubscriptionLifecycle> createState() =>
      _SubscriptionLifecycleState();
}

class _SubscriptionLifecycleState extends ConsumerState<SubscriptionLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(subscriptionProvider.notifier).sync();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

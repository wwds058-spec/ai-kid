import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../curriculum/episode_controller.dart';
import '../storage/models/subscription_state.dart';

/// Live view of the cached entitlement. Screens watch this, so a purchase
/// or restore in the parent dashboard unlocks content without a restart.
class SubscriptionNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() =>
      ref.read(hiveStorageServiceProvider).getSubscription();

  /// Re-read after PurchaseService has written a new entitlement.
  void refresh() =>
      state = ref.read(hiveStorageServiceProvider).getSubscription();
}

final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionState>(
        SubscriptionNotifier.new);

/// True while Premium content may be played (includes the 3-day grace).
final isPremiumProvider =
    Provider<bool>((ref) => ref.watch(subscriptionProvider).isActiveWithGrace);

import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_state.freezed.dart';
part 'subscription_state.g.dart';

/// Source of truth is RevenueCat; this is a local cache so the app
/// works offline without hitting RC on every launch.
@freezed
class SubscriptionState with _$SubscriptionState {
  const factory SubscriptionState({
    @Default(false) bool isPremium,
    DateTime? expiresAt,
    /// e.g. 'ai_explorer_monthly' | 'ai_explorer_annual' | 'ai_explorer_family'
    String? productId,
    /// UTC timestamp when we last verified with RevenueCat
    DateTime? lastVerifiedAt,
    /// False once the parent cancels: Premium stays until [expiresAt].
    @Default(true) bool willRenew,
    /// Google Play reported a payment problem (Play's own grace period).
    @Default(false) bool billingIssue,
  }) = _SubscriptionState;

  const SubscriptionState._();

  /// Grace period: treat as premium for 3 days after expiry
  /// so the child isn't mid-episode when the card expires.
  bool get isActiveWithGrace {
    if (!isPremium) return false;
    if (expiresAt == null) return true; // lifetime / no expiry
    return DateTime.now().isBefore(expiresAt!.add(const Duration(days: 3)));
  }

  factory SubscriptionState.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStateFromJson(json);
}

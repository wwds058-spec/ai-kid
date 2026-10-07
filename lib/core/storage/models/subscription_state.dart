import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'subscription_state.freezed.dart';
part 'subscription_state.g.dart';

/// Hive typeId 3
/// Source of truth is RevenueCat; this is a local cache so the app
/// works offline without hitting RC on every launch.
@freezed
@HiveType(typeId: 3)
class SubscriptionState with _$SubscriptionState {
  const factory SubscriptionState({
    @HiveField(0) @Default(false) bool isPremium,
    @HiveField(1) DateTime? expiresAt,
    /// e.g. 'ai_explorer_monthly' | 'ai_explorer_annual' | 'ai_explorer_family'
    @HiveField(2) String? productId,
    /// UTC timestamp when we last verified with RevenueCat
    @HiveField(3) DateTime? lastVerifiedAt,
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

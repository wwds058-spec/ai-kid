import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory record of a successful parent PIN check.
///
/// The router refuses `/parent-dashboard` unless [isUnlocked], so the
/// dashboard can't be reached by a direct navigation that skips the PIN gate.
/// The unlock expires after [ttl] and is never persisted, so a restart or a
/// child picking up the device later always meets the PIN again.
class ParentGate {
  ParentGate({this.ttl = const Duration(minutes: 5), DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final Duration ttl;
  final DateTime Function() _now;
  DateTime? _unlockedAt;

  bool get isUnlocked {
    final at = _unlockedAt;
    return at != null && _now().difference(at) < ttl;
  }

  /// Call only after the PIN has been verified (or just set).
  void unlock() => _unlockedAt = _now();

  /// Call when the parent leaves the dashboard.
  void lock() => _unlockedAt = null;
}

final parentGateProvider = Provider<ParentGate>((ref) => ParentGate());

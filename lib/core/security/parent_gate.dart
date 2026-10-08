import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory record of a successful parent PIN check.
///
/// The router refuses `/parent-dashboard` unless [isUnlocked], so the
/// dashboard can't be reached by a direct navigation that skips the PIN gate.
/// The unlock expires after [ttl] and is never persisted, so a restart or a
/// child picking up the device later always meets the PIN again.
class ParentGate {
  ParentGate({this.ttl = const Duration(minutes: 5), Duration Function()? elapsed})
      : _elapsed = elapsed ?? (Stopwatch()..start()).elapsedFunc;

  final Duration ttl;

  /// Monotonic time (an in-process stopwatch): the unlock window can't be
  /// stretched by changing the device clock.
  final Duration Function() _elapsed;
  Duration? _unlockedAt;

  bool get isUnlocked {
    final at = _unlockedAt;
    return at != null && _elapsed() - at < ttl;
  }

  /// Call only after the PIN has been verified (or just set).
  void unlock() => _unlockedAt = _elapsed();

  /// Call when the parent leaves the dashboard.
  void lock() => _unlockedAt = null;
}

extension on Stopwatch {
  Duration Function() get elapsedFunc => () => elapsed;
}

final parentGateProvider = Provider<ParentGate>((ref) => ParentGate());

import 'dart:math';

import '../storage/models/parent_settings.dart';

/// Wrong-PIN lockout rules. State lives in [ParentSettings] so it survives
/// leaving the PIN screen and restarting the app.
///
/// After [maxAttempts] wrong entries (PIN or grown-up check), entry is
/// refused for [baseCooldown]; each further lockout doubles it, up to
/// [maxCooldown]. A correct PIN resets everything.
///
/// Time is measured on a monotonic clock (`elapsed`, see MonotonicClock),
/// never the wall clock, so changing the device date/time cannot shorten a
/// lock. The lock stores the time still to wait and a checkpoint on that
/// clock. After a reboot the clock restarts below the checkpoint; no time is
/// credited for the reboot gap and the lock resumes from what was left at
/// the last checkpoint (a reboot can lengthen a lock, never shorten it).
class PinLockout {
  static const maxAttempts = 3;
  static const baseCooldown = Duration(minutes: 5);
  static const maxCooldown = Duration(hours: 1);

  static Duration remaining(ParentSettings s, Duration elapsed) {
    final left = s.lockRemainingMs;
    final at = s.lockCheckpointMs;
    if (left == null || at == null || left <= 0) return Duration.zero;
    final passed = elapsed.inMilliseconds - at;
    // passed < 0 means the device rebooted since the checkpoint.
    final credited = passed < 0 ? 0 : passed;
    return Duration(milliseconds: max(0, left - credited));
  }

  static bool isLocked(ParentSettings s, Duration elapsed) =>
      remaining(s, elapsed) > Duration.zero;

  /// Persist progress so a later reboot only loses time since this call.
  static ParentSettings checkpoint(ParentSettings s, Duration elapsed) {
    if (s.lockRemainingMs == null) return s;
    final left = remaining(s, elapsed);
    return left == Duration.zero
        ? s.copyWith(lockRemainingMs: null, lockCheckpointMs: null)
        : s.copyWith(
            lockRemainingMs: left.inMilliseconds,
            lockCheckpointMs: elapsed.inMilliseconds);
  }

  static int attemptsLeft(ParentSettings s) => maxAttempts - s.failedPinAttempts;

  static ParentSettings recordFailure(ParentSettings s, Duration elapsed) {
    final attempts = s.failedPinAttempts + 1;
    if (attempts < maxAttempts) return s.copyWith(failedPinAttempts: attempts);

    final lockouts = s.pinLockouts + 1;
    final minutes = min(
      baseCooldown.inMinutes * pow(2, lockouts - 1),
      maxCooldown.inMinutes,
    ).toInt();
    return s.copyWith(
      failedPinAttempts: 0,
      pinLockouts: lockouts,
      lockRemainingMs: Duration(minutes: minutes).inMilliseconds,
      lockCheckpointMs: elapsed.inMilliseconds,
    );
  }

  static ParentSettings recordSuccess(ParentSettings s) => s.copyWith(
      failedPinAttempts: 0,
      pinLockouts: 0,
      lockRemainingMs: null,
      lockCheckpointMs: null);
}

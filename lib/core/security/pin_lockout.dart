import 'dart:math';

import '../storage/models/parent_settings.dart';

/// Wrong-PIN lockout rules. State lives in [ParentSettings] so it survives
/// leaving the PIN screen and restarting the app.
///
/// After [maxAttempts] wrong PINs, entry is refused for [baseCooldown]; each
/// further lockout doubles the cooldown, up to [maxCooldown]. A correct PIN
/// resets everything.
class PinLockout {
  static const maxAttempts = 3;
  static const baseCooldown = Duration(minutes: 5);
  static const maxCooldown = Duration(hours: 1);

  static bool isLocked(ParentSettings s, DateTime now) =>
      s.pinLockedUntil != null && now.isBefore(s.pinLockedUntil!);

  static Duration remaining(ParentSettings s, DateTime now) =>
      isLocked(s, now) ? s.pinLockedUntil!.difference(now) : Duration.zero;

  static int attemptsLeft(ParentSettings s) => maxAttempts - s.failedPinAttempts;

  static ParentSettings recordFailure(ParentSettings s, DateTime now) {
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
      pinLockedUntil: now.add(Duration(minutes: minutes)),
    );
  }

  static ParentSettings recordSuccess(ParentSettings s) =>
      s.copyWith(failedPinAttempts: 0, pinLockouts: 0, pinLockedUntil: null);
}

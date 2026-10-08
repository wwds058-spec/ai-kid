import 'package:ai_explorer/core/security/pin_lockout.dart';
import 'package:ai_explorer/core/storage/models/parent_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 12);

  ParentSettings failTimes(ParentSettings s, int n, DateTime now) {
    for (var i = 0; i < n; i++) {
      s = PinLockout.recordFailure(s, now);
    }
    return s;
  }

  test('two failures count down attempts without locking', () {
    final s = failTimes(const ParentSettings(), 2, t0);
    expect(PinLockout.attemptsLeft(s), 1);
    expect(PinLockout.isLocked(s, t0), isFalse);
  });

  test('third failure locks for 5 minutes, then unlocks', () {
    final s = failTimes(const ParentSettings(), 3, t0);
    expect(PinLockout.isLocked(s, t0), isTrue);
    expect(PinLockout.remaining(s, t0), const Duration(minutes: 5));
    expect(PinLockout.isLocked(s, t0.add(const Duration(minutes: 5))), isFalse);
    expect(PinLockout.attemptsLeft(s), 3, reason: 'fresh attempts after lock');
  });

  test('each further lockout doubles the cooldown, capped at 1 hour', () {
    var s = const ParentSettings();
    var now = t0;
    final cooldowns = <int>[];
    for (var i = 0; i < 6; i++) {
      s = failTimes(s, 3, now);
      cooldowns.add(PinLockout.remaining(s, now).inMinutes);
      now = s.pinLockedUntil!;
    }
    expect(cooldowns, [5, 10, 20, 40, 60, 60]);
  });

  test('correct PIN resets attempts, lockouts and lock time', () {
    final s = PinLockout.recordSuccess(failTimes(const ParentSettings(), 5, t0));
    expect(s.failedPinAttempts, 0);
    expect(s.pinLockouts, 0);
    expect(s.pinLockedUntil, isNull);
  });

  test('settings saved before these fields existed still load', () {
    final s = ParentSettings.fromJson({'dailyLimitMinutes': 30});
    expect(s.failedPinAttempts, 0);
    expect(s.pinLockedUntil, isNull);
  });
}

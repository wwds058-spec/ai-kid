import 'dart:io';
import 'dart:math';

import 'package:ai_explorer/core/security/grown_up_check.dart';
import 'package:ai_explorer/core/security/pin_lockout.dart';
import 'package:ai_explorer/core/storage/models/parent_settings.dart';
import 'package:ai_explorer/l10n/parent_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const t0 = Duration(hours: 10); // monotonic: time since boot

  ParentSettings failTimes(ParentSettings s, int n, Duration at) {
    for (var i = 0; i < n; i++) {
      s = PinLockout.recordFailure(s, at);
    }
    return s;
  }

  test('two failures count down attempts without locking', () {
    final s = failTimes(const ParentSettings(), 2, t0);
    expect(PinLockout.attemptsLeft(s), 1);
    expect(PinLockout.isLocked(s, t0), isFalse);
  });

  test('third failure locks for 5 minutes of real elapsed time', () {
    final s = failTimes(const ParentSettings(), 3, t0);
    expect(PinLockout.remaining(s, t0), const Duration(minutes: 5));
    expect(PinLockout.isLocked(s, t0 + const Duration(minutes: 4, seconds: 59)),
        isTrue);
    expect(PinLockout.isLocked(s, t0 + const Duration(minutes: 5)), isFalse);
    expect(PinLockout.attemptsLeft(s), 3, reason: 'fresh attempts after lock');
  });

  test('each further lockout doubles the cooldown, capped at 1 hour', () {
    var s = const ParentSettings();
    var now = t0;
    final cooldowns = <int>[];
    for (var i = 0; i < 6; i++) {
      s = failTimes(s, 3, now);
      final r = PinLockout.remaining(s, now);
      cooldowns.add(r.inMinutes);
      now += r;
    }
    expect(cooldowns, [5, 10, 20, 40, 60, 60]);
  });

  test('correct PIN resets attempts, lockouts and the lock', () {
    final s = PinLockout.recordSuccess(failTimes(const ParentSettings(), 5, t0));
    expect(s.failedPinAttempts, 0);
    expect(s.pinLockouts, 0);
    expect(PinLockout.isLocked(s, t0), isFalse);
  });

  group('regression: device clock and reboot cannot bypass the lock', () {
    test('lockout code never reads the wall clock', () {
      for (final f in [
        'lib/core/security/pin_lockout.dart',
        'lib/core/security/parent_gate.dart',
        'lib/features/parent_dashboard/pin_gate_screen.dart',
      ]) {
        expect(File(f).readAsStringSync(), isNot(contains('DateTime.now')),
            reason: '$f must use MonotonicClock, not the settable wall clock');
      }
    });

    test('reboot right after locking: lock keeps its full remaining time', () {
      final s = failTimes(const ParentSettings(), 3, t0);
      const afterReboot = Duration(seconds: 30); // clock restarted
      expect(PinLockout.remaining(s, afterReboot), const Duration(minutes: 5));
    });

    test('reboot mid-lock resumes from the last checkpoint', () {
      var s = failTimes(const ParentSettings(), 3, t0);
      s = PinLockout.checkpoint(s, t0 + const Duration(minutes: 2));
      const boot = Duration(seconds: 20);
      expect(PinLockout.remaining(s, boot), const Duration(minutes: 3),
          reason: 'reboot gap not credited, but earlier waiting is kept');
      s = PinLockout.checkpoint(s, boot); // gate shown after reboot
      expect(PinLockout.isLocked(s, boot + const Duration(minutes: 2, seconds: 59)),
          isTrue);
      expect(PinLockout.isLocked(s, boot + const Duration(minutes: 3)), isFalse);
    });

    test('checkpoint clears an expired lock', () {
      final s = failTimes(const ParentSettings(), 3, t0);
      final c = PinLockout.checkpoint(s, t0 + const Duration(minutes: 6));
      expect(c.lockRemainingMs, isNull);
      expect(c.lockCheckpointMs, isNull);
    });
  });

  test('settings saved before these fields existed still load', () {
    final s = ParentSettings.fromJson({'dailyLimitMinutes': 30});
    expect(s.failedPinAttempts, 0);
    expect(PinLockout.isLocked(s, t0), isFalse);
  });

  group('grown-up check', () {
    test('four digits 1-9, no immediate repeats, shown as words', () {
      for (var seed = 0; seed < 200; seed++) {
        final c = GrownUpCheck.random(Random(seed));
        expect(c.digits, hasLength(4));
        expect(c.digits.every((d) => d >= 1 && d <= 9), isTrue);
        for (var i = 1; i < 4; i++) {
          expect(c.digits[i], isNot(c.digits[i - 1]));
        }
      }
      final c = GrownUpCheck([7, 2, 9, 4]);
      expect(c.prompt(ParentStrings.en.digitWords), 'seven  two  nine  four');
      expect(c.check('7294'), isTrue);
      expect(c.check('7249'), isFalse);
      expect(c.prompt(ParentStrings.en.digitWords), isNot(contains('7')),
          reason: 'digits must not be shown as numerals');
    });
  });
}

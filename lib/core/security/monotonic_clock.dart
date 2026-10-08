import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Time that only moves forward and can't be set by the user.
///
/// On Android this is SystemClock.elapsedRealtime() (time since boot,
/// including sleep), read once at launch through a platform channel and then
/// advanced with an in-process stopwatch so reads are synchronous.
/// It restarts from zero on reboot; callers detect that as time going
/// backwards (see PinLockout).
abstract class MonotonicClock {
  Duration elapsed();
}

class PlatformMonotonicClock implements MonotonicClock {
  PlatformMonotonicClock._(this._base);

  static const _channel = MethodChannel('ai_explorer/clock');
  final Duration _base;
  final Stopwatch _sinceLaunch = Stopwatch()..start();

  /// Reads the boot clock. If the platform channel is unavailable (tests,
  /// non-Android), starts from zero: lockouts then only count down while the
  /// app runs — stricter, never bypassable.
  static Future<PlatformMonotonicClock> create() async {
    Duration base = Duration.zero;
    try {
      final ms = await _channel.invokeMethod<int>('elapsedRealtime');
      if (ms != null) base = Duration(milliseconds: ms);
    } on PlatformException {
      // fall through
    } on MissingPluginException {
      // fall through
    }
    return PlatformMonotonicClock._(base);
  }

  @override
  Duration elapsed() => _base + _sinceLaunch.elapsed;
}

/// Overridden in main() with the platform clock; tests use a fake.
final monotonicClockProvider = Provider<MonotonicClock>(
    (ref) => throw StateError('monotonicClockProvider not initialised'));

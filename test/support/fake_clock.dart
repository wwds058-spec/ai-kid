import 'package:ai_explorer/core/security/monotonic_clock.dart';

/// Monotonic clock tests can advance or "reboot".
class FakeClock implements MonotonicClock {
  FakeClock([this.now = const Duration(hours: 10)]);
  Duration now;
  void advance(Duration d) => now += d;
  void reboot([Duration upFor = const Duration(seconds: 30)]) => now = upFor;
  @override
  Duration elapsed() => now;
}

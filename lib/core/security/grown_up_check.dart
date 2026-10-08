import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parental gate shown before a parent PIN can be created.
///
/// Four random digits are shown as words ("seven  two  nine  four") and must
/// be typed on the keypad. Easy for an adult, not for a pre-reader aged 5–7,
/// so the first person to open the parent area can't simply be the child.
/// Wrong answers count toward the PIN lockout.
class GrownUpCheck {
  GrownUpCheck(this.digits) : assert(digits.length == length);

  static const length = 4;
  final List<int> digits;

  /// Digits 1–9 only ('zero' vs 'o' confusion), no immediate repeats.
  factory GrownUpCheck.random(Random random) {
    final d = <int>[];
    while (d.length < length) {
      final n = 1 + random.nextInt(9);
      if (d.isEmpty || d.last != n) d.add(n);
    }
    return GrownUpCheck(d);
  }

  String get answer => digits.join();

  String prompt(List<String> digitWords) =>
      digits.map((n) => digitWords[n]).join('  ');

  bool check(String entry) => entry == answer;
}

/// Source of randomness for the check; tests pin it with a seeded Random.
final grownUpRandomProvider = Provider<Random>((ref) => Random.secure());

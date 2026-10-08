import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/security/grown_up_check.dart';
import '../../core/security/monotonic_clock.dart';
import '../../core/security/parent_gate.dart';
import '../../core/security/pin_lockout.dart';
import '../../core/security/pin_service.dart';
import '../../core/storage/models/parent_settings.dart';
import '../../curriculum/episode_controller.dart';
import '../../l10n/language.dart';
import '../../l10n/parent_strings.dart';

/// PIN gate that sits in front of [ParentDashboardScreen].
///
///  • No PIN set → grown-up check ([GrownUpCheck]) → create PIN → confirm
///  • PIN set    → enter PIN
///  • 3 wrong entries (PIN or grown-up check) lock entry for a cooldown that
///    persists across visits and restarts and ignores the device clock
///    ([PinLockout] on a [MonotonicClock]).
class PinGateScreen extends ConsumerStatefulWidget {
  const PinGateScreen({super.key});

  @override
  ConsumerState<PinGateScreen> createState() => _PinGateScreenState();
}

enum _Stage { grownUpCheck, createPin, confirmPin, enterPin }

class _PinGateScreenState extends ConsumerState<PinGateScreen> {
  static const int _kPinLength = 4;

  String _entry = '';
  String _newPin = '';
  late _Stage _stage;
  GrownUpCheck? _check;
  bool _checkWasWrong = false;
  Timer? _tick;

  ParentSettings get _settings =>
      ref.read(hiveStorageServiceProvider).getSettings();
  Duration get _now => ref.read(monotonicClockProvider).elapsed();
  bool get _locked => PinLockout.isLocked(_settings, _now);

  @override
  void initState() {
    super.initState();
    if (_settings.pinHash != null) {
      _stage = _Stage.enterPin;
    } else {
      _stage = _Stage.grownUpCheck;
      _newCheck();
    }
    _checkpoint();
    // Re-check the lock regularly: rebuild when it ends, and checkpoint so a
    // reboot only loses the time since the last tick.
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      _checkpoint();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _newCheck() =>
      _check = GrownUpCheck.random(ref.read(grownUpRandomProvider));

  void _checkpoint() {
    final storage = ref.read(hiveStorageServiceProvider);
    final s = storage.getSettings();
    final next = PinLockout.checkpoint(s, _now);
    if (next != s) storage.saveSettings(next);
  }

  Future<void> _fail() async {
    final storage = ref.read(hiveStorageServiceProvider);
    await storage.saveSettings(
        PinLockout.recordFailure(storage.getSettings(), _now));
  }

  void _onKey(String digit) {
    if (_locked || _entry.length >= _kPinLength) return;
    setState(() => _entry += digit);
    if (_entry.length == _kPinLength) _submit();
  }

  void _onDelete() {
    if (_entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _submit() async {
    final entry = _entry;
    setState(() => _entry = '');
    final storage = ref.read(hiveStorageServiceProvider);
    switch (_stage) {
      case _Stage.grownUpCheck:
        if (_check!.check(entry)) {
          setState(() {
            _stage = _Stage.createPin;
            _checkWasWrong = false;
          });
        } else {
          await _fail();
          setState(() {
            _checkWasWrong = true;
            _newCheck();
          });
        }
      case _Stage.createPin:
        setState(() {
          _newPin = entry;
          _stage = _Stage.confirmPin;
        });
      case _Stage.confirmPin:
        if (entry != _newPin) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ref.read(parentStringsProvider).pinsDidNotMatch)));
          }
          setState(() => _stage = _Stage.createPin);
          return;
        }
        await storage.saveSettings(PinLockout.recordSuccess(
            storage.getSettings().copyWith(pinHash: PinService.hash(_newPin))));
        _open();
      case _Stage.enterPin:
        final s = storage.getSettings();
        if (PinService.verify(entry, s.pinHash ?? '')) {
          await storage.saveSettings(PinLockout.recordSuccess(s));
          _open();
        } else {
          await _fail();
          setState(() {});
        }
    }
  }

  void _open() {
    ref.read(parentGateProvider).unlock();
    if (mounted) context.go(Routes.parentDashboard);
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(parentStringsProvider);
    final locked = _locked;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(p.parentArea,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AIExplorerTheme.purple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.worldMap),
        ),
      ),
      body: Center(
        // Scrolls on short screens instead of overflowing.
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(p, locked),
                const SizedBox(height: 32),
                _buildDots(),
                const SizedBox(height: 32),
                if (locked)
                  _LockedMessage(p.tryAgainIn(
                      PinLockout.remaining(_settings, _now).inMinutes + 1))
                else
                  _buildKeypad(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _title = TextStyle(
      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700);
  static const _warn = TextStyle(color: Colors.orangeAccent, fontSize: 14);

  Widget _buildHeader(ParentStrings p, bool locked) {
    if (locked) {
      return Text(p.tooManyAttempts,
          style: const TextStyle(color: Colors.redAccent, fontSize: 18),
          textAlign: TextAlign.center);
    }
    final attemptsLeft = PinLockout.attemptsLeft(_settings);
    final showAttempts = _settings.failedPinAttempts > 0;
    return switch (_stage) {
      _Stage.grownUpCheck => Column(children: [
          Text(p.grownUpCheckTitle, style: _title, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(p.grownUpCheckPrompt,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(_check!.prompt(p.digitWords),
              key: const ValueKey('grown_up_prompt'),
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          if (_checkWasWrong)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(p.grownUpCheckWrong, style: _warn),
            ),
        ]),
      _Stage.createPin =>
        Text(p.createPin, style: _title, textAlign: TextAlign.center),
      _Stage.confirmPin =>
        Text(p.confirmPin, style: _title, textAlign: TextAlign.center),
      _Stage.enterPin => Column(children: [
          Text(p.enterPin, style: _title),
          if (showAttempts)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(p.wrongPin(attemptsLeft), style: _warn),
            ),
        ]),
    };
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_kPinLength, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 20, height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < _entry.length ? AIExplorerTheme.purple : Colors.white24,
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (final row in [['1','2','3'], ['4','5','6'], ['7','8','9']])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final digit in row)
                GestureDetector(
                  onTap: () => _onKey(digit),
                  child: _KeyButton(digit),
                ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 88),
            GestureDetector(onTap: () => _onKey('0'), child: const _KeyButton('0')),
            GestureDetector(
              onTap: _onDelete,
              child: const _KeyButton('⌫', isDelete: true),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final bool isDelete;
  const _KeyButton(this.label, {this.isDelete = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: isDelete ? Colors.transparent : Colors.white10,
        borderRadius: BorderRadius.circular(36),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isDelete ? 24 : 28,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}

class _LockedMessage extends StatelessWidget {
  final String text;
  const _LockedMessage(this.text);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('🔒', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(text,
            style: const TextStyle(color: Colors.white54, fontSize: 16),
            textAlign: TextAlign.center),
      ],
    );
  }
}

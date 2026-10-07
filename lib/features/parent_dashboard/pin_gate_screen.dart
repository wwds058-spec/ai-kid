import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/security/pin_service.dart';
import '../../curriculum/episode_controller.dart';

/// PIN gate that sits in front of [ParentDashboardScreen].
///
/// Behaviour:
///  • No PIN set → shows "Create PIN" flow (first-time setup)
///  • PIN set    → shows keypad to verify; locks after 3 wrong attempts
class PinGateScreen extends ConsumerStatefulWidget {
  const PinGateScreen({super.key});

  @override
  ConsumerState<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends ConsumerState<PinGateScreen> {
  String _entry = '';
  String _confirmEntry = '';      // used during set-PIN flow
  bool _isConfirmStep = false;    // set-PIN step 2
  int _wrongAttempts = 0;
  bool _locked = false;

  static const int _kMaxAttempts = 3;
  static const int _kPinLength = 4;

  bool get _hasPinSet {
    final settings = ref.read(hiveStorageServiceProvider).getSettings();
    return settings.pinHash != null;
  }

  void _onKey(String digit) {
    if (_locked) return;
    setState(() {
      if (_isConfirmStep) {
        if (_confirmEntry.length < _kPinLength) {
          _confirmEntry += digit;
          if (_confirmEntry.length == _kPinLength) _finishSetPin();
        }
      } else {
        if (_entry.length < _kPinLength) {
          _entry += digit;
          if (_entry.length == _kPinLength) {
            _hasPinSet ? _verify() : _finishEnterPin();
          }
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (_isConfirmStep) {
        if (_confirmEntry.isNotEmpty) {
          _confirmEntry = _confirmEntry.substring(0, _confirmEntry.length - 1);
        }
      } else {
        if (_entry.isNotEmpty) {
          _entry = _entry.substring(0, _entry.length - 1);
        }
      }
    });
  }

  /// Step 1 done — move to confirm
  void _finishEnterPin() {
    setState(() {
      _isConfirmStep = true;
      _confirmEntry = '';
    });
  }

  /// Step 2 done — save hashed PIN and navigate into dashboard
  void _finishSetPin() {
    if (_entry != _confirmEntry) {
      // Pins don't match — restart
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PINs did not match. Try again.')));
      setState(() {
        _entry = '';
        _confirmEntry = '';
        _isConfirmStep = false;
      });
      return;
    }
    final storage = ref.read(hiveStorageServiceProvider);
    final settings = storage.getSettings();
    storage.saveSettings(settings.copyWith(pinHash: PinService.hash(_entry)));
    context.go('/parent-dashboard');
  }

  void _verify() {
    final settings = ref.read(hiveStorageServiceProvider).getSettings();
    final correct = PinService.verify(_entry, settings.pinHash ?? '');
    if (correct) {
      context.go('/parent-dashboard');
    } else {
      setState(() {
        _wrongAttempts++;
        _entry = '';
        if (_wrongAttempts >= _kMaxAttempts) _locked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Parent Area',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AIExplorerTheme.purple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/world-map'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildDots(),
              const SizedBox(height: 40),
              if (_locked)
                const _LockedMessage()
              else
                _buildKeypad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_locked) {
      return const Text('Too many wrong attempts.',
          style: TextStyle(color: Colors.redAccent, fontSize: 18),
          textAlign: TextAlign.center);
    }
    if (!_hasPinSet) {
      return Text(
        _isConfirmStep ? 'Confirm your PIN' : 'Create a 4-digit PIN',
        style: const TextStyle(color: Colors.white, fontSize: 22,
            fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
      );
    }
    final remaining = _kMaxAttempts - _wrongAttempts;
    return Column(
      children: [
        const Text('Enter parent PIN',
            style: TextStyle(color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.w700)),
        if (_wrongAttempts > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Wrong PIN. $remaining attempt${remaining == 1 ? '' : 's'} left.',
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildDots() {
    final filled = _isConfirmStep ? _confirmEntry.length : _entry.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_kPinLength, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 20, height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled
                ? AIExplorerTheme.purple
                : Colors.white24,
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
            children: row.map(_KeyButton.new).map((b) => b.onTap == null
                ? b
                : GestureDetector(onTap: () => _onKey(b.label), child: b))
                .toList(),
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
  final VoidCallback? onTap;

  const _KeyButton(this.label, {this.isDelete = false, this.onTap});

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
  const _LockedMessage();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('🔒', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text(
          'Close and reopen the app to try again.',
          style: TextStyle(color: Colors.white54, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

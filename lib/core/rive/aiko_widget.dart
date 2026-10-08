import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Aiko character widget driven by a Rive state machine.
///
/// State machine name: "Aiko_Controller"
/// Inputs:
///   - emotion (String trigger)  — excited | curious | happy | celebrate | sad | normal
///   - isTalking (Boolean)       — true while audio is playing
///
/// Place the compiled .riv file at:  assets/rive/aiko.riv
///
/// ─── Phase 2 checklist ─────────────────────────────────────────────────────
/// [ ] Export Rive file from Rive editor → save as assets/rive/aiko.riv
/// [ ] Confirm state-machine name matches kStateMachine below
/// [ ] Confirm input names match kEmotionInput / kTalkingInput below
/// ───────────────────────────────────────────────────────────────────────────
class AikoWidget extends StatefulWidget {
  /// Episode `emotion` values. Rive doesn't support string inputs, so each
  /// maps to the numeric 'emotion' input; indices must match the state
  /// machine. Episodes may only use these keys (checked by content tests).
  static const emotionIndex = <String, double>{
    'normal':    0,
    'happy':     1,
    'excited':   2,
    'curious':   3,
    'celebrate': 4,
    'sad':       5,
  };

  /// Emotion string as defined in EpisodeScript.emotion
  final String emotion;

  /// True while the AudioService is playing a line so Aiko's mouth moves.
  final bool isTalking;

  const AikoWidget({
    super.key,
    required this.emotion,
    this.isTalking = false,
  });

  @override
  State<AikoWidget> createState() => _AikoWidgetState();
}

class _AikoWidgetState extends State<AikoWidget> {
  static const String kStateMachine = 'Aiko_Controller';
  static const String kEmotionInput = 'emotion';
  static const String kTalkingInput = 'isTalking';

  StateMachineController? _controller;
  SMIInput<bool>? _talkingInput;

  SMIInput<double>? _emotionInput;

  void _onRiveInit(Artboard artboard) {
    final ctrl = StateMachineController.fromArtboard(artboard, kStateMachine);
    if (ctrl == null) return;
    artboard.addController(ctrl);
    _controller = ctrl;

    _emotionInput = ctrl.findInput<double>(kEmotionInput);
    _talkingInput = ctrl.findInput<bool>(kTalkingInput);

    _applyEmotion(widget.emotion);
    _applyTalking(widget.isTalking);
  }

  void _applyEmotion(String emotion) {
    _emotionInput?.value = AikoWidget.emotionIndex[emotion] ?? 0;
  }

  void _applyTalking(bool talking) {
    _talkingInput?.value = talking;
  }

  @override
  void didUpdateWidget(AikoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion) _applyEmotion(widget.emotion);
    if (oldWidget.isTalking != widget.isTalking) _applyTalking(widget.isTalking);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: RiveAnimation.asset(
        'assets/rive/aiko.riv',
        stateMachines: const [kStateMachine],
        onInit: _onRiveInit,
        // Fallback while asset loads or if .riv is missing in dev
        placeHolder: _AikoFallback(emotion: widget.emotion),
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Shown while Rive is loading or the .riv file hasn't been added yet.
class _AikoFallback extends StatelessWidget {
  final String emotion;
  const _AikoFallback({required this.emotion});

  static const _emoji = {
    'excited': '🤩', 'curious': '🤔', 'happy': '😄',
    'celebrate': '🎉', 'normal': '🙂', 'sad': '😟',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_emoji[emotion] ?? '🙂',
            style: const TextStyle(fontSize: 100)),
        // Emotion label is a developer aid only; children never see it.
        if (kDebugMode) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Aiko · $emotion',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ),
        ],
      ],
    );
  }
}

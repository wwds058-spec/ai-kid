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
  /// Aiko's six states: five poses selected by the state machine's
  /// `emotion` Number input, plus `talking`, driven by the `isTalking`
  /// Boolean input while a line is actually playing (it layers the mouth /
  /// gesture animation over the current pose).
  ///
  /// Pose indices must match the Rive state machine ([kStateMachine]).
  /// Episodes may only use these pose names (checked by content tests).
  /// Spec for the animator: docs/AIKO_CHARACTER.md.
  static const emotionIndex = <String, double>{
    'idle':      0,
    'excited':   1,
    'curious':   2,
    'celebrate': 3,
    'oops':      4,
  };

  /// All six states, for documentation and contract checks.
  static const states = ['idle', 'talking', 'excited', 'curious', 'celebrate', 'oops'];

  static const kAsset = 'assets/rive/aiko.riv';
  static const kStateMachine = 'Aiko_Controller';
  static const kEmotionInput = 'emotion';
  static const kTalkingInput = 'isTalking';

  /// The character file, loaded once per app run. Null if it is missing or
  /// unreadable: Aiko then shows as the emoji fallback instead of throwing.
  static Future<RiveFile?>? _riveFile;

  /// Forget the cached load (tests run many app lifetimes in one process).
  @visibleForTesting
  static void resetRiveCache() => _riveFile = null;
  static Future<RiveFile?> loadRiveFile() => _riveFile ??= () async {
        try {
          return await RiveFile.asset(AikoWidget.kAsset);
        } catch (e, st) {
          // Only path to the emoji fallback in a release build. Reported as
          // an error (logcat / any attached crash reporter), not swallowed.
          FlutterError.reportError(FlutterErrorDetails(
            exception: e,
            stack: st,
            library: 'aiko_widget',
            context: ErrorDescription(
                'loading ${AikoWidget.kAsset}; showing emoji fallback'),
          ));
          return null;
        }
      }();

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
  static const kStateMachine = AikoWidget.kStateMachine;
  static const kEmotionInput = AikoWidget.kEmotionInput;
  static const kTalkingInput = AikoWidget.kTalkingInput;

  StateMachineController? _controller;
  SMIInput<bool>? _talkingInput;

  SMIInput<double>? _emotionInput;

  void _onRiveInit(Artboard artboard) {
    final ctrl = StateMachineController.fromArtboard(artboard, kStateMachine);
    if (ctrl == null) {
      _reportContract('state machine "$kStateMachine" not found');
      return;
    }
    artboard.addController(ctrl);
    _controller = ctrl;

    _emotionInput = ctrl.findInput<double>(kEmotionInput);
    _talkingInput = ctrl.findInput<bool>(kTalkingInput);
    if (_emotionInput == null) _reportContract('Number input "$kEmotionInput" missing');
    if (_talkingInput == null) _reportContract('Boolean input "$kTalkingInput" missing');

    _applyEmotion(widget.emotion);
    _applyTalking(widget.isTalking);
  }

  /// A broken character file must be loud, not a silently frozen Aiko.
  static void _reportContract(String problem) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: StateError('${AikoWidget.kAsset}: $problem'),
      library: 'aiko_widget',
      context: ErrorDescription('Aiko Rive contract (docs/AIKO_CHARACTER.md)'),
    ));
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
    final fallback = _AikoFallback(emotion: widget.emotion);
    return SizedBox(
      width: 240,
      height: 240,
      child: FutureBuilder<RiveFile?>(
        future: AikoWidget.loadRiveFile(),
        builder: (context, snap) {
          final file = snap.data;
          if (file == null) return fallback;
          return RiveAnimation.direct(
            file,
            stateMachines: const [kStateMachine],
            onInit: _onRiveInit,
            placeHolder: fallback,
            fit: BoxFit.contain,
          );
        },
      ),
    );
  }
}

/// Shown while Rive is loading or the .riv file hasn't been added yet.
class _AikoFallback extends StatelessWidget {
  final String emotion;
  const _AikoFallback({required this.emotion});

  static const _emoji = {
    'excited': '🤩', 'curious': '🤔', 'idle': '🙂',
    'celebrate': '🎉', 'oops': '🙈',
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

import 'dart:io';

import 'package:ai_explorer/core/rive/aiko_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/rive_inspect.dart';

/// Problems with [bytes] as Aiko's character file, or empty if it fits the
/// contract in docs/AIKO_CHARACTER.md.
List<String> aikoContractProblems(List<int> bytes,
    {String stateMachine = AikoWidget.kStateMachine,
    String numberInput = AikoWidget.kEmotionInput,
    String boolInput = AikoWidget.kTalkingInput}) {
  final List<RiveArtboardInfo> artboards;
  try {
    artboards = inspectRive(bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
  } catch (e) {
    return ['not a readable .riv file: $e'];
  }
  if (artboards.isEmpty) return ['no artboard'];
  final sm = artboards.first.stateMachines
      .where((m) => m.name == stateMachine)
      .firstOrNull;
  if (sm == null) {
    return ['first artboard "${artboards.first.name}" has no state machine '
        '"$stateMachine" (found: ${artboards.first.stateMachines.map((m) => m.name).join(', ')})'];
  }
  return [
    if (!sm.inputs.any((i) => i.name == numberInput && i.type == 'number'))
      'Number input "$numberInput" missing',
    if (!sm.inputs.any((i) => i.name == boolInput && i.type == 'bool'))
      'Boolean input "$boolInput" missing',
  ];
}

void main() {
  final isRelease = Platform.environment['RELEASE'] == '1';
  final aiko = File(AikoWidget.kAsset);

  group('contract checker (against real Rive files)', () {
    test('accepts a file with the required state machine and inputs', () {
      // Rive's own fixture: artboard CircleOuter / CircleStateMachine has a
      // Number and a Boolean input — the same shape Aiko needs.
      final bytes = File('test/fixtures/rive/runtime_nested_inputs.riv').readAsBytesSync();
      final artboards = inspectRive(bytes);
      final outer = artboards.firstWhere((a) => a.name == 'CircleOuter');
      final sm = outer.stateMachines.single;
      expect(sm.name, 'CircleStateMachine');
      expect(sm.inputs.map((i) => '${i.name}:${i.type}'),
          containsAll(['CircleOuterNumber:number', 'CircleOuterState:bool']));
    });

    test('rejects a file without Aiko_Controller', () {
      final bytes = File('test/fixtures/rive/electrified_button_simple.riv').readAsBytesSync();
      expect(aikoContractProblems(bytes), isNotEmpty);
    });

    test('rejects a file with the state machine but wrong inputs', () {
      final bytes = File('test/fixtures/rive/electrified_button_simple.riv').readAsBytesSync();
      expect(
          aikoContractProblems(bytes, stateMachine: 'button'),
          contains('Number input "emotion" missing'));
    });

    test('rejects garbage', () {
      expect(aikoContractProblems([1, 2, 3, 4]), isNotEmpty);
    });
  });

  test('the six Aiko states: five poses + talking', () {
    expect(AikoWidget.states,
        ['idle', 'talking', 'excited', 'curious', 'celebrate', 'oops']);
    expect(AikoWidget.emotionIndex.keys.toSet(),
        AikoWidget.states.toSet().difference({'talking'}));
    expect(AikoWidget.emotionIndex.values.toList(), [0, 1, 2, 3, 4]);
  });

  test('assets/rive/aiko.riv meets the contract', () {
    expect(aiko.existsSync(), isTrue,
        reason: 'Aiko character missing: deliver ${AikoWidget.kAsset} '
            '(docs/AIKO_CHARACTER.md)');
    expect(aikoContractProblems(aiko.readAsBytesSync()), isEmpty);
  },
      skip: isRelease || aiko.existsSync()
          ? false
          : 'Aiko .riv not delivered yet (required when RELEASE=1)');

  testWidgets('missing character file: emoji stand-in AND a reported error',
      (tester) async {
    if (aiko.existsSync()) return; // only meaningful before delivery
    rootBundle.clear();
    AikoWidget.resetRiveCache();
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(const MaterialApp(
        home: AikoWidget(emotion: 'oops', isTalking: false)));
    await tester.pumpAndSettle();
    FlutterError.onError = previous;

    expect(find.text('🙈'), findsOneWidget, reason: 'oops stand-in');
    expect(errors.where((e) => e.library == 'aiko_widget'), hasLength(1),
        reason: 'the failure must be reported, not swallowed');
  });
}

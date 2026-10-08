// Reads a .riv file's artboards, state machines and inputs WITHOUT
// instantiating Rive objects (which needs native libraries that
// flutter_tester lacks). Uses the runtime's own header reader and
// property decoders, so the format rules match the shipped runtime.
// ignore_for_file: implementation_imports
import 'dart:collection';
import 'dart:typed_data';

import 'package:rive/src/core/field_types/core_field_type.dart';
import 'package:rive/src/generated/rive_core_context.dart';
import 'package:rive/src/rive_core/runtime/runtime_header.dart';
import 'package:rive_common/utilities.dart';

class RiveInput {
  final String name;
  final String type; // number | bool | trigger
  const RiveInput(this.name, this.type);
}

class RiveStateMachineInfo {
  final String name;
  final List<RiveInput> inputs = [];
  RiveStateMachineInfo(this.name);
}

class RiveArtboardInfo {
  final String name;
  final List<RiveStateMachineInfo> stateMachines = [];
  RiveArtboardInfo(this.name);
}

const _artboard = 1, _stateMachine = 53;
const _inputTypes = {56: 'number', 59: 'bool', 58: 'trigger'};
const _componentName = 4, _animationName = 55, _smComponentName = 138;

List<RiveArtboardInfo> inspectRive(Uint8List bytes) {
  final reader = BinaryReader(ByteData.sublistView(bytes));
  final header = RuntimeHeader.read(reader);
  final toc = HashMap<int, CoreFieldType>();
  header.propertyToFieldIndex.forEach((key, index) {
    toc[key] = switch (index) {
      0 => RiveCoreContext.uintType,
      1 => RiveCoreContext.stringType,
      2 => RiveCoreContext.doubleType,
      _ => RiveCoreContext.colorType,
    };
  });

  final artboards = <RiveArtboardInfo>[];
  while (!reader.isEOF) {
    final typeKey = reader.readVarUint();
    String? name;
    while (true) {
      final key = reader.readVarUint();
      if (key == 0) break;
      final type = RiveCoreContext.coreType(key) ?? toc[key];
      if (type == null) {
        throw FormatException('unknown property $key: newer Rive runtime needed');
      }
      final isName = key == _componentName ||
          key == _animationName ||
          key == _smComponentName;
      if (isName && type == RiveCoreContext.stringType) {
        name = type.deserialize(reader) as String;
      } else {
        type.skip(reader);
      }
    }
    if (typeKey == _artboard) {
      artboards.add(RiveArtboardInfo(name ?? ''));
    } else if (typeKey == _stateMachine && artboards.isNotEmpty) {
      artboards.last.stateMachines.add(RiveStateMachineInfo(name ?? ''));
    } else if (_inputTypes.containsKey(typeKey) &&
        artboards.isNotEmpty &&
        artboards.last.stateMachines.isNotEmpty) {
      artboards.last.stateMachines.last.inputs
          .add(RiveInput(name ?? '', _inputTypes[typeKey]!));
    }
  }
  return artboards;
}

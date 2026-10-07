import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'parent_settings.freezed.dart';
part 'parent_settings.g.dart';

/// Hive typeId 2
@freezed
@HiveType(typeId: 2)
class ParentSettings with _$ParentSettings {
  const factory ParentSettings({
    @HiveField(0) @Default(30) int dailyLimitMinutes,
    @HiveField(1) @Default(true) bool voiceEnabled,
    @HiveField(2) @Default(true) bool aiInteractionEnabled,
    /// SHA-256 hash of parent PIN (never store plain PIN)
    @HiveField(3) String? pinHash,
    /// Log of disclosure events (child said something sensitive) — no audio stored
    @HiveField(4) @Default([]) List<String> disclosureLog,
  }) = _ParentSettings;

  factory ParentSettings.fromJson(Map<String, dynamic> json) =>
      _$ParentSettingsFromJson(json);
}

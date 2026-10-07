import 'package:freezed_annotation/freezed_annotation.dart';

part 'parent_settings.freezed.dart';
part 'parent_settings.g.dart';

@freezed
class ParentSettings with _$ParentSettings {
  const factory ParentSettings({
    @Default(30) int dailyLimitMinutes,
    @Default(true) bool voiceEnabled,
    @Default(true) bool aiInteractionEnabled,
    /// SHA-256 hash of parent PIN (never store plain PIN)
    String? pinHash,
    /// Log of disclosure events (child said something sensitive) — no audio stored
    @Default([]) List<String> disclosureLog,
  }) = _ParentSettings;

  factory ParentSettings.fromJson(Map<String, dynamic> json) =>
      _$ParentSettingsFromJson(json);
}

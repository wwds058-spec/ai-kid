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
    /// Wrong PIN entries since the last success or lockout (see PinLockout)
    @Default(0) int failedPinAttempts,
    /// Lockouts since the last correct PIN; each one doubles the cooldown
    @Default(0) int pinLockouts,
    /// PIN entry is refused until this time
    DateTime? pinLockedUntil,
  }) = _ParentSettings;

  factory ParentSettings.fromJson(Map<String, dynamic> json) =>
      _$ParentSettingsFromJson(json);
}

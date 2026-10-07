import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'child_profile.freezed.dart';
part 'child_profile.g.dart';

/// Hive typeId 0
@freezed
@HiveType(typeId: 0)
class ChildProfile with _$ChildProfile {
  const factory ChildProfile({
    @HiveField(0) required String id,
    @HiveField(1) required String nickname,
    @HiveField(2) @Default(0) int avatarIndex,
    @HiveField(3) @Default('en') String language,  // 'en' | 'hi' | 'te'
    @HiveField(4) @Default(6) int ageYears,
    @HiveField(5) required DateTime createdAt,
  }) = _ChildProfile;

  factory ChildProfile.fromJson(Map<String, dynamic> json) =>
      _$ChildProfileFromJson(json);
}

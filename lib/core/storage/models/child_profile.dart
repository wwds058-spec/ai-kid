import 'package:freezed_annotation/freezed_annotation.dart';

part 'child_profile.freezed.dart';
part 'child_profile.g.dart';

@freezed
abstract class ChildProfile with _$ChildProfile {
  const factory ChildProfile({
    required String id,
    required String nickname,
    @Default(0) int avatarIndex,
    @Default('en') String language,  // 'en' | 'hi' | 'te'
    @Default(6) int ageYears,
    required DateTime createdAt,
  }) = _ChildProfile;

  factory ChildProfile.fromJson(Map<String, dynamic> json) =>
      _$ChildProfileFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'episode_progress.freezed.dart';
part 'episode_progress.g.dart';

/// Hive typeId 1
@freezed
@HiveType(typeId: 1)
class EpisodeProgress with _$EpisodeProgress {
  const factory EpisodeProgress({
    @HiveField(0) required String episodeId,
    @HiveField(1) @Default(false) bool completed,
    @HiveField(2) @Default(0) int lastStepIndex,
    @HiveField(3) @Default([]) List<String> badgesEarned,
    @HiveField(4) required DateTime lastPlayedAt,
    @HiveField(5) @Default(0) int totalPlaySeconds,
  }) = _EpisodeProgress;

  factory EpisodeProgress.fromJson(Map<String, dynamic> json) =>
      _$EpisodeProgressFromJson(json);
}

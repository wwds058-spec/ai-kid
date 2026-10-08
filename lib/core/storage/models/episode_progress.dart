import 'package:freezed_annotation/freezed_annotation.dart';

part 'episode_progress.freezed.dart';
part 'episode_progress.g.dart';

@freezed
abstract class EpisodeProgress with _$EpisodeProgress {
  const factory EpisodeProgress({
    required String episodeId,
    @Default(false) bool completed,
    @Default(0) int lastStepIndex,
    @Default([]) List<String> badgesEarned,
    required DateTime lastPlayedAt,
    @Default(0) int totalPlaySeconds,
  }) = _EpisodeProgress;

  factory EpisodeProgress.fromJson(Map<String, dynamic> json) =>
      _$EpisodeProgressFromJson(json);
}

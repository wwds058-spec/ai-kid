import 'package:ai_explorer/core/storage/hive_storage_service.dart';
import 'package:ai_explorer/core/storage/models/child_profile.dart';
import 'package:ai_explorer/core/storage/models/episode_progress.dart';
import 'package:ai_explorer/core/storage/models/parent_settings.dart';
import 'package:ai_explorer/core/storage/models/subscription_state.dart';

/// In-memory [HiveStorageService] for tests.
class FakeStorage implements HiveStorageService {
  FakeStorage({
    this.profile,
    Map<String, EpisodeProgress>? progress,
    this.settings = const ParentSettings(),
    this.sub = const SubscriptionState(),
  }) : progress = progress ?? {};

  ChildProfile? profile;
  final Map<String, EpisodeProgress> progress;
  ParentSettings settings;
  SubscriptionState sub;

  @override
  ChildProfile? getProfile() => profile;
  @override
  Future<void> saveProfile(ChildProfile p) async => profile = p;

  @override
  EpisodeProgress? getProgress(String id) => progress[id];
  @override
  Future<void> saveProgress(EpisodeProgress p) async => progress[p.episodeId] = p;
  @override
  List<EpisodeProgress> allProgress() => progress.values.toList();

  @override
  ParentSettings getSettings() => settings;
  @override
  Future<void> saveSettings(ParentSettings s) async => settings = s;

  @override
  SubscriptionState getSubscription() => sub;
  @override
  Future<void> saveSubscription(SubscriptionState s) async => sub = s;
}

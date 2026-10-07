import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'models/child_profile.dart';
import 'models/episode_progress.dart';
import 'models/parent_settings.dart';
import 'models/subscription_state.dart';

/// Initialise Hive and open all boxes.
/// Call once in main() before runApp().
///
/// Models are persisted as JSON strings (freezed `toJson`/`fromJson`),
/// so no Hive type adapters or hive_generator are needed.
class HiveStorageService {
  static const _profileBox      = 'child_profiles';
  static const _progressBox     = 'episode_progress';
  static const _settingsBox     = 'parent_settings';
  static const _subscriptionBox = 'subscription_state';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<String>(_profileBox),
      Hive.openBox<String>(_progressBox),
      Hive.openBox<String>(_settingsBox),
      Hive.openBox<String>(_subscriptionBox),
    ]);
  }

  static Map<String, dynamic> _decode(String raw) =>
      jsonDecode(raw) as Map<String, dynamic>;

  // ── Child profile ──────────────────────────────────────────────────────────
  Box<String> get _profiles => Hive.box<String>(_profileBox);

  ChildProfile? getProfile() {
    final raw = _profiles.get('current');
    return raw == null ? null : ChildProfile.fromJson(_decode(raw));
  }

  Future<void> saveProfile(ChildProfile profile) =>
      _profiles.put('current', jsonEncode(profile.toJson()));

  // ── Episode progress ───────────────────────────────────────────────────────
  Box<String> get _progress => Hive.box<String>(_progressBox);

  EpisodeProgress? getProgress(String episodeId) {
    final raw = _progress.get(episodeId);
    return raw == null ? null : EpisodeProgress.fromJson(_decode(raw));
  }

  Future<void> saveProgress(EpisodeProgress progress) =>
      _progress.put(progress.episodeId, jsonEncode(progress.toJson()));

  List<EpisodeProgress> allProgress() => _progress.values
      .map((raw) => EpisodeProgress.fromJson(_decode(raw)))
      .toList();

  // ── Parent settings ────────────────────────────────────────────────────────
  Box<String> get _settings => Hive.box<String>(_settingsBox);

  ParentSettings getSettings() {
    final raw = _settings.get('settings');
    return raw == null
        ? const ParentSettings()
        : ParentSettings.fromJson(_decode(raw));
  }

  Future<void> saveSettings(ParentSettings settings) =>
      _settings.put('settings', jsonEncode(settings.toJson()));

  // ── Subscription state ─────────────────────────────────────────────────────
  Box<String> get _sub => Hive.box<String>(_subscriptionBox);

  SubscriptionState getSubscription() {
    final raw = _sub.get('sub');
    return raw == null
        ? const SubscriptionState()
        : SubscriptionState.fromJson(_decode(raw));
  }

  Future<void> saveSubscription(SubscriptionState sub) =>
      _sub.put('sub', jsonEncode(sub.toJson()));
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parent controls whose model and storage exist (ParentSettings) but whose
/// behaviour isn't shipped yet. Disabled controls are hidden, never deleted,
/// so turning one on later needs no data migration or screen rework.
class FeatureFlags {
  /// Daily screen-time limit (ParentSettings.dailyLimitMinutes).
  /// Off until the limit is enforced by the episode engine.
  /// Enable in a test build: --dart-define=FEATURE_DAILY_LIMIT=true
  final bool dailyLimit;

  /// AI interaction toggle (ParentSettings.aiInteractionEnabled).
  /// This MVP has no generative AI, so it is always off in builds; only
  /// tests may switch it on to exercise the gated control.
  final bool aiInteraction;

  const FeatureFlags({this.dailyLimit = false, this.aiInteraction = false});

  static const build = FeatureFlags(
    dailyLimit: bool.fromEnvironment('FEATURE_DAILY_LIMIT'),
  );
}

final featureFlagsProvider = Provider<FeatureFlags>((ref) => FeatureFlags.build);

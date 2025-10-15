/// Centralized feature flag definitions.
/// Use these toggles so unfinished features can be disabled at runtime.
class FeatureFlags {
  FeatureFlags._();

  /// Enables the parent-only, on-device video workflow.
  static const bool parentLocalVideos = true;
}

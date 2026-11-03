import 'package:flutter/services.dart';

/// Semantic haptic feedback. Call the variant that matches the moment rather
/// than picking an intensity.
abstract final class Haptics {
  /// Picking from a set: tabs, segmented controls, pickers.
  static void selection() => HapticFeedback.selectionClick();

  /// Pressing a primary control.
  static void tap() => HapticFeedback.lightImpact();

  /// Something was created or completed.
  static void success() => HapticFeedback.mediumImpact();

  /// A destructive action is about to happen or has happened.
  static void warning() => HapticFeedback.heavyImpact();
}

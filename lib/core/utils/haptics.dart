import 'package:flutter/services.dart';

/// Centralized haptic feedback so intensity stays consistent app-wide.
class Haptics {
  Haptics._();

  static void selection() => HapticFeedback.selectionClick();
  static void light() => HapticFeedback.lightImpact();
  static void success() => HapticFeedback.mediumImpact();
  static void warning() => HapticFeedback.heavyImpact();
}

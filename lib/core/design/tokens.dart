import 'package:flutter/material.dart';

/// PulseVote design tokens.
///
/// Brand voice: participation, trust, momentum, clarity, inclusion.
/// Deliberately non-political: teal/indigo core with a warm coral accent.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0E7C6B); // deep teal
  static const Color primaryBright = Color(0xFF14B8A0);
  static const Color indigo = Color(0xFF4F5DD3);
  static const Color coral = Color(0xFFFF7A59);
  static const Color amber = Color(0xFFF5A623);

  // Neutrals
  static const Color ink = Color(0xFF15201E);
  static const Color inkMuted = Color(0xFF5A6B68);
  static const Color surfaceLight = Color(0xFFF7FAF9);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF101817);
  static const Color cardDark = Color(0xFF1B2523);

  // Semantic
  static const Color success = Color(0xFF1E9E6A);
  static const Color warning = Color(0xFFB97A08);
  static const Color danger = Color(0xFFD64545);
  static const Color info = Color(0xFF3B82C4);

  /// Color-blind-safe categorical palette (Okabe–Ito derived) used for
  /// candidate avatars and result bars. Never the only channel of meaning.
  static const List<Color> categorical = [
    Color(0xFF0072B2),
    Color(0xFFE69F00),
    Color(0xFF009E73),
    Color(0xFFCC79A7),
    Color(0xFF56B4E9),
    Color(0xFFD55E00),
    Color(0xFF8C7AE6),
    Color(0xFF999999),
  ];

  static Color categoricalFor(int seed) =>
      categorical[seed % categorical.length];

  /// Cover gradients for event artwork (asset-free, lightweight).
  static const List<List<Color>> coverGradients = [
    [Color(0xFF0E7C6B), Color(0xFF14B8A0)],
    [Color(0xFF4F5DD3), Color(0xFF8C7AE6)],
    [Color(0xFF0072B2), Color(0xFF56B4E9)],
    [Color(0xFFD55E00), Color(0xFFF5A623)],
    [Color(0xFF7B4397), Color(0xFFCC79A7)],
    [Color(0xFF11655B), Color(0xFF3B82C4)],
  ];

  static List<Color> coverGradientFor(int seed) =>
      coverGradients[seed % coverGradients.length];
}

class Spacing {
  Spacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class Corners {
  Corners._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

class Elevations {
  Elevations._();
  static const double none = 0;
  static const double card = 1;
  static const double raised = 3;
  static const double overlay = 8;
}

class Motion {
  Motion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration emphasized = Duration(milliseconds: 400);
  static const Curve easing = Curves.easeOutCubic;

  /// Honor the platform reduced-motion preference.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.of(context).disableAnimations ? Duration.zero : duration;
}

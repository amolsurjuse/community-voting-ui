import 'package:flutter/material.dart';

import '../../domain/models/candidate.dart';
import '../design/tokens.dart';

/// Asset-free gradient avatar with initials. Keeps the app lightweight while
/// giving each candidate a distinct, accessible identity.
class CandidateAvatar extends StatelessWidget {
  const CandidateAvatar({super.key, required this.candidate, this.size = 52});

  final Candidate candidate;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = AppColors.categoricalFor(candidate.colorSeed);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, 0.25)!],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        candidate.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Event cover artwork: brand gradient + emoji, no image assets required.
class EventCoverArt extends StatelessWidget {
  const EventCoverArt({
    super.key,
    required this.coverSeed,
    required this.emoji,
    this.height = 160,
    this.borderRadius,
  });

  final int coverSeed;
  final String emoji;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.coverGradientFor(coverSeed);
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(Corners.lg),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -22,
              child: Opacity(
                opacity: 0.25,
                child: Text(emoji, style: TextStyle(fontSize: height * 0.85)),
              ),
            ),
            Center(child: Text(emoji, style: TextStyle(fontSize: height * 0.32))),
          ],
        ),
      ),
    );
  }
}

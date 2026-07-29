import 'package:flutter/material.dart';

import '../../domain/models/candidate.dart';
import '../design/tokens.dart';
import '../utils/formatters.dart';
import 'candidate_avatar.dart';

/// Horizontal result bar for a candidate: count + percentage + animated fill.
/// Communicates rank with position, label and icon — never color alone.
class ResultBar extends StatelessWidget {
  const ResultBar({
    super.key,
    required this.candidate,
    required this.votes,
    required this.fraction,
    this.isLeading = false,
    this.isTied = false,
    this.showCounts = true,
  });

  final Candidate candidate;
  final int votes;
  final double fraction;
  final bool isLeading;
  final bool isTied;
  final bool showCounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = AppColors.categoricalFor(candidate.colorSeed);
    final label = showCounts
        ? '${candidate.name}: ${Formatters.compactCount(votes)} votes, ${Formatters.percent(fraction)}'
        : '${candidate.name}: counts hidden until minimum participation is reached';

    return Semantics(
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CandidateAvatar(candidate: candidate, size: 36),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          candidate.name,
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLeading) ...[
                        const SizedBox(width: Spacing.sm),
                        Icon(
                          isTied ? Icons.balance : Icons.emoji_events_outlined,
                          size: 16,
                          color: AppColors.amber,
                          semanticLabel: isTied ? 'Tied for first' : 'Leading',
                        ),
                      ],
                    ],
                  ),
                ),
                if (showCounts)
                  Text.rich(
                    TextSpan(
                      text: Formatters.percent(fraction),
                      style: theme.textTheme.titleSmall,
                      children: [
                        TextSpan(
                          text: '  ·  ${Formatters.compactCount(votes)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(Corners.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: showCounts ? fraction : 0),
                duration: Motion.of(context, Motion.emphasized),
                curve: Motion.easing,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

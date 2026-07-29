import 'package:flutter/material.dart';

import '../../domain/models/event.dart';
import '../design/tokens.dart';
import '../utils/formatters.dart';
import 'badges.dart';
import 'candidate_avatar.dart';

/// Card used across discovery, home and management lists.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.trailing,
    this.showStatus = false,
  });

  final VotingEvent event;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventCoverArt(
                coverSeed: event.coverSeed,
                emoji: event.coverEmoji,
                height: 64,
                borderRadius: BorderRadius.circular(Corners.md),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: theme.textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      event.organizerName,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (showStatus) StatusBadge(status: event.status),
                        VerificationBadge(level: event.verificationLevel, compact: true),
                        Text(
                          event.isClosed
                              ? '${Formatters.compactCount(event.totalBallots)} ballots'
                              : Formatters.countdown(event.endsAt),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

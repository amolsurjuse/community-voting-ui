import 'package:flutter/material.dart';

import '../../domain/models/enums.dart';
import '../design/tokens.dart';

/// Pill badge communicating an event's verification level.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.level, this.compact = false});

  final VerificationLevel level;
  final bool compact;

  IconData get _icon => switch (level) {
        VerificationLevel.basicInstall => Icons.smartphone,
        VerificationLevel.verifiedInstall => Icons.verified_user_outlined,
        VerificationLevel.phone => Icons.sms_outlined,
        VerificationLevel.invitation => Icons.mail_outline,
        VerificationLevel.organizerApproval => Icons.how_to_reg_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Verification: ${level.label}. ${level.summary}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? Spacing.sm : Spacing.md,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(Corners.pill),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: compact ? 13 : 15, color: scheme.primary),
            const SizedBox(width: Spacing.xs),
            Text(
              level.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Event lifecycle status chip (icon + label; never color alone).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final EventStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      EventStatus.draft => ('Draft', AppColors.inkMuted, Icons.edit_outlined),
      EventStatus.scheduled => ('Scheduled', AppColors.info, Icons.schedule),
      EventStatus.open => ('Voting open', AppColors.success, Icons.play_circle_outline),
      EventStatus.closed => ('Closed', AppColors.warning, Icons.flag_outlined),
      EventStatus.archived => ('Archived', AppColors.inkMuted, Icons.inventory_2_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Corners.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Public / Unlisted / Private indicator.
class VisibilityBadge extends StatelessWidget {
  const VisibilityBadge({super.key, required this.visibility});

  final EventVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final icon = switch (visibility) {
      EventVisibility.public => Icons.public,
      EventVisibility.unlisted => Icons.link,
      EventVisibility.private => Icons.lock_outline,
    };
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: muted),
        const SizedBox(width: Spacing.xs),
        Text(
          visibility.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}

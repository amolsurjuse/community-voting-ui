import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/candidate_avatar.dart';
import '../../core/widgets/common.dart';
import '../../domain/models/enums.dart';
import 'ballot_controller.dart';

/// Pre-submission review: selections, ranking order, verification method and
/// a deliberate — but not frightening — finality notice.
Future<void> showBallotReviewSheet(
  BuildContext context, {
  required BallotFlowState state,
  required Future<void> Function() onSubmit,
}) {
  return showAppSheet(
    context,
    child: _ReviewSheet(state: state, onSubmit: onSubmit),
  );
}

class _ReviewSheet extends StatelessWidget {
  const _ReviewSheet({required this.state, required this.onSubmit});

  final BallotFlowState state;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = state.event!;
    final draft = state.draft!;
    final byId = {for (final c in event.activeCandidates) c.id: c};
    final isRanked = event.rules.ballotType == BallotType.rankedChoice;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Review your ballot', style: theme.textTheme.headlineSmall),
          const SizedBox(height: Spacing.xs),
          Text(event.title, style: theme.textTheme.bodySmall),
          const SizedBox(height: Spacing.lg),
          ...draft.selections.asMap().entries.map((entry) {
            final candidate = byId[entry.value]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: Row(
                children: [
                  if (isRanked) ...[
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                  ] else ...[
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 22),
                    const SizedBox(width: Spacing.md),
                  ],
                  CandidateAvatar(candidate: candidate, size: 36),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child:
                        Text(candidate.name, style: theme.textTheme.titleSmall),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: Spacing.xl),
          Row(
            children: [
              Text('Verification', style: theme.textTheme.bodySmall),
              const Spacer(),
              VerificationBadge(level: event.verificationLevel, compact: true),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          const InfoCallout(
            icon: Icons.gpp_good_outlined,
            text:
                'Review your ballot carefully. After it is accepted, it cannot be changed.',
          ),
          const SizedBox(height: Spacing.xl),
          FilledButton(
            onPressed: () {
              Haptics.success();
              Navigator.of(context).pop();
              onSubmit();
            },
            child: const Text('Submit ballot'),
          ),
          const SizedBox(height: Spacing.sm),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep editing'),
          ),
        ],
      ),
    );
  }
}

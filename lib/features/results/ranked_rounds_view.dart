import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../domain/models/event.dart';
import '../../domain/models/results.dart';

/// Round-by-round instant-runoff visualization: eliminations, transfers,
/// majority threshold and winner, with an expandable explanation.
class RankedRoundsView extends StatelessWidget {
  const RankedRoundsView(
      {super.key, required this.event, required this.snapshot});

  final VotingEvent event;
  final ResultsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rounds = snapshot.rankedRounds;
    if (rounds.isEmpty) return const SizedBox.shrink();
    final byId = {for (final c in event.activeCandidates) c.id: c};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Round-by-round count', style: theme.textTheme.titleMedium),
        const SizedBox(height: Spacing.sm),
        Text(
          'Counting method: ${event.rules.rankedAlgorithm}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: Spacing.md),
        for (final round in rounds) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Round ${round.round}',
                          style: theme.textTheme.titleSmall),
                      const Spacer(),
                      if (round.winnerCandidateId != null)
                        const Icon(Icons.emoji_events,
                            size: 18, color: AppColors.amber),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  for (final tally in round.tallies)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              byId[tally.candidateId]?.name ?? '—',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight:
                                    tally.candidateId == round.winnerCandidateId
                                        ? FontWeight.w700
                                        : null,
                                decoration: tally.candidateId ==
                                        round.eliminatedCandidateId
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tally.candidateId == round.eliminatedCandidateId)
                            Padding(
                              padding: const EdgeInsets.only(right: Spacing.sm),
                              child: Text('eliminated',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.danger,
                                  )),
                            ),
                          Text(
                            Formatters.compactCount(tally.votes),
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  if (round.note.isNotEmpty) ...[
                    const SizedBox(height: Spacing.sm),
                    Text(round.note, style: theme.textTheme.bodySmall),
                  ],
                  if (round.transferredVotes > 0)
                    Row(
                      children: [
                        const Icon(Icons.arrow_downward,
                            size: 14, color: AppColors.info),
                        const SizedBox(width: Spacing.xs),
                        Text(
                          '${round.transferredVotes} ballots transferred to next choices',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
        ],
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('How ranked-choice counting works',
              style: theme.textTheme.titleSmall),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.lg),
              child: Text(
                'Each ballot counts for its highest-ranked candidate still in '
                'the running. If no candidate holds a majority of active '
                'ballots, the candidate with the fewest votes is eliminated '
                'and their ballots move to each voter\'s next choice. Rounds '
                'repeat until a candidate reaches a majority. Different '
                'organizations use different ranked-vote methods — this event '
                'uses: ${event.rules.rankedAlgorithm}.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        InfoCallout(
          icon: Icons.balance,
          text: 'Tie-breaking: ${event.rules.tieBreakPolicy}',
        ),
      ],
    );
  }
}

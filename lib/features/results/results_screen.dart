import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/result_bar.dart';
import '../../core/widgets/states.dart';
import '../../data/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/event.dart';
import '../../domain/models/results.dart';
import '../event/event_details_screen.dart';
import 'ranked_rounds_view.dart';

final resultsStreamProvider = StreamProvider.autoDispose
    .family<ResultsSnapshot, String>((ref, eventId) {
  return ref.watch(resultsRepositoryProvider).watchResults(eventId);
});

/// Live/final results with color-blind-safe horizontal bars and ranked rounds.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, required this.publicId});

  final String publicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvent = ref.watch(eventByPublicIdProvider(publicId));
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: SafeArea(
        child: asyncEvent.when(
          loading: () => const SkeletonList(items: 5, itemHeight: 72),
          error: (_, __) => ErrorPanel(
            message: 'Could not load this event.',
            onRetry: () => ref.invalidate(eventByPublicIdProvider(publicId)),
          ),
          data: (event) {
            if (event == null) {
              return EmptyState(
                icon: Icons.link_off,
                title: 'Event not found',
                message: 'This link may be invalid or expired.',
                actionLabel: 'Explore events',
                onAction: () => context.go('/discover'),
              );
            }
            if (!event.canSeeResults(hasVoted: true) &&
                event.resultVisibility == ResultVisibility.organizerOnly) {
              return const EmptyState(
                icon: Icons.visibility_off_outlined,
                title: 'Results are private',
                message: 'The organizer has chosen to keep results visible only to themselves.',
              );
            }
            if (!event.isClosed &&
                event.resultVisibility == ResultVisibility.afterClose) {
              return EmptyState(
                icon: Icons.schedule,
                title: 'Results after the event closes',
                message: event.endsAt != null
                    ? 'Results will be published when voting ends: ${Formatters.dateTime(event.endsAt!)}.'
                    : 'Results will be published when the organizer closes voting.',
              );
            }
            return _ResultsBody(event: event);
          },
        ),
      ),
    );
  }
}

class _ResultsBody extends ConsumerWidget {
  const _ResultsBody({required this.event});

  final VotingEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSnapshot = ref.watch(resultsStreamProvider(event.id));
    final theme = Theme.of(context);
    final isRanked = event.rules.ballotType == BallotType.rankedChoice;

    return asyncSnapshot.when(
      loading: () => const SkeletonList(items: 5, itemHeight: 72),
      error: (_, __) => ErrorPanel(
        message:
            'The live results stream disconnected. Pull to refresh or retry.',
        onRetry: () => ref.invalidate(resultsStreamProvider(event.id)),
      ),
      data: (snapshot) {
        final byId = {for (final c in event.activeCandidates) c.id: c};
        final leaders = snapshot.leaders.toSet();
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(resultsStreamProvider(event.id)),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Spacing.lg),
            children: [
              Text(event.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  if (!snapshot.isFinal) ...[
                    const _LiveDot(),
                    const SizedBox(width: Spacing.xs),
                    Text('Live', style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w700,
                    )),
                    const SizedBox(width: Spacing.md),
                  ] else ...[
                    const Icon(Icons.flag, size: 14, color: AppColors.warning),
                    const SizedBox(width: Spacing.xs),
                    Text('Final', style: theme.textTheme.labelSmall),
                    const SizedBox(width: Spacing.md),
                  ],
                  Text(
                    '${Formatters.compactCount(snapshot.totalBallots)} ballots · '
                    'updated ${Formatters.relative(snapshot.updatedAt)}',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              if (snapshot.isTie) ...[
                const SizedBox(height: Spacing.md),
                const InfoCallout(
                  icon: Icons.balance,
                  text: 'There is currently a tie for first place.',
                ),
              ],
              const SizedBox(height: Spacing.lg),
              if (snapshot.belowThreshold)
                const InfoCallout(
                  icon: Icons.visibility_off_outlined,
                  text: 'Counts are hidden until a minimum number of ballots is '
                      'reached, to protect early-voter privacy.',
                )
              else if (isRanked) ...[
                Text('First choices', style: theme.textTheme.titleMedium),
                const SizedBox(height: Spacing.sm),
                for (final tally in snapshot.sorted)
                  ResultBar(
                    candidate: byId[tally.candidateId]!,
                    votes: tally.votes,
                    fraction: snapshot.fraction(tally.candidateId),
                    isLeading: leaders.contains(tally.candidateId),
                    isTied: snapshot.isTie,
                  ),
                const SizedBox(height: Spacing.xl),
                RankedRoundsView(event: event, snapshot: snapshot),
              ] else
                for (final tally in snapshot.sorted)
                  ResultBar(
                    candidate: byId[tally.candidateId]!,
                    votes: tally.votes,
                    fraction: snapshot.fraction(tally.candidateId),
                    isLeading: leaders.contains(tally.candidateId),
                    isTied: snapshot.isTie,
                  ),
              const SizedBox(height: Spacing.xl),
              if (!snapshot.isFinal)
                Text(
                  'Live results can change until voting closes.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: Spacing.xl),
            ],
          ),
        );
      },
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return FadeTransition(
      opacity: reduceMotion
          ? const AlwaysStoppedAnimation(1)
          : Tween(begin: 0.4, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

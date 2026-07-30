import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/candidate_avatar.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/states.dart';
import '../../data/providers.dart';
import '../../domain/models/candidate.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/event.dart';
import 'candidate_sheet.dart';
import 'share_sheet.dart';

final eventByPublicIdProvider =
    FutureProvider.family<VotingEvent?, String>((ref, publicId) async {
  final event =
      await ref.watch(eventRepositoryProvider).getByPublicId(publicId);
  if (event != null) {
    await ref.read(ballotRepositoryProvider).rememberEvent(publicId);
  }
  return event;
});

/// Participant-facing event page. Shows what the event is about before any
/// verification is requested.
class EventDetailsScreen extends ConsumerWidget {
  const EventDetailsScreen({super.key, required this.publicId});

  final String publicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvent = ref.watch(eventByPublicIdProvider(publicId));
    return Scaffold(
      body: asyncEvent.when(
        loading: () =>
            const SafeArea(child: SkeletonList(items: 4, itemHeight: 120)),
        error: (_, __) => SafeArea(
          child: ErrorPanel(
            message: 'We could not load this event. Check your connection.',
            onRetry: () => ref.invalidate(eventByPublicIdProvider(publicId)),
          ),
        ),
        data: (event) => event == null
            ? SafeArea(
                child: EmptyState(
                  icon: Icons.link_off,
                  title: 'Event not found',
                  message:
                      'This link may be invalid, expired, or point to a private event you don\'t have access to.',
                  actionLabel: 'Explore public events',
                  onAction: () => context.go('/discover'),
                ),
              )
            : _EventBody(event: event),
      ),
    );
  }
}

class _EventBody extends ConsumerWidget {
  const _EventBody({required this.event});

  final VotingEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final candidates = event.activeCandidates;
    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(eventByPublicIdProvider(event.publicId)),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            leading: _CircleButton(
              icon: Icons.arrow_back,
              tooltip: 'Back',
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/discover'),
            ),
            actions: [
              _CircleButton(
                icon: Icons.share_outlined,
                tooltip: 'Share event',
                onTap: () => showShareSheet(context, event),
              ),
              const SizedBox(width: Spacing.sm),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: EventCoverArt(
                coverSeed: event.coverSeed,
                emoji: event.coverEmoji,
                height: 280,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.xs,
                    children: [
                      StatusBadge(status: event.status),
                      VerificationBadge(level: event.verificationLevel),
                      VisibilityBadge(visibility: event.visibility),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(event.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      Icon(
                        event.organizerVerified
                            ? Icons.verified
                            : Icons.person_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Flexible(
                        child: Text(
                          'Organized by ${event.organizerName}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (event.shortDescription.isNotEmpty) ...[
                    const SizedBox(height: Spacing.lg),
                    Text(event.shortDescription,
                        style: theme.textTheme.bodyLarge),
                  ],
                  if (event.longDescription.isNotEmpty) ...[
                    const SizedBox(height: Spacing.sm),
                    Text(
                      event.longDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.xl),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Column(
                        children: [
                          InfoRow(
                            icon: Icons.how_to_vote_outlined,
                            label: 'Voting method',
                            value:
                                '${event.rules.ballotType.label} — ${_rulesSummary(event)}',
                          ),
                          InfoRow(
                            icon: Icons.timer_outlined,
                            label: 'Deadline',
                            value: event.isClosed
                                ? 'Closed ${event.endsAt != null ? Formatters.dateTime(event.endsAt!) : ''}'
                                : event.endsAt == null
                                    ? 'Open until the organizer closes it'
                                    : '${Formatters.countdown(event.endsAt)} · ${Formatters.dateTime(event.endsAt!)}',
                          ),
                          InfoRow(
                            icon: Icons.bar_chart,
                            label: 'Results',
                            value: event.resultVisibility.explanation,
                          ),
                          InfoRow(
                            icon: Icons.group_outlined,
                            label: 'Options',
                            value:
                                '${candidates.length} ${event.rules.ballotType == BallotType.rankedChoice ? 'to rank' : 'to choose from'}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  InfoCallout(
                    icon: Icons.privacy_tip_outlined,
                    text:
                        '${event.verificationLevel.detail} Your ballot is anonymous: '
                        'the receipt confirms acceptance without revealing your choices.',
                  ),
                  SectionHeader(title: 'Options (${candidates.length})'),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            sliver: SliverList.separated(
              itemCount: candidates.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
              itemBuilder: (context, i) => _CandidatePreviewCard(
                candidate: candidates[i],
                onTap: () => showCandidateSheet(context, candidates[i]),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    ).withVoteBar(context, event);
  }

  static String _rulesSummary(VotingEvent event) =>
      switch (event.rules.ballotType) {
        BallotType.singleChoice => 'pick one',
        BallotType.multipleChoice =>
          'pick ${event.rules.minSelections}–${event.rules.maxSelections}',
        BallotType.rankedChoice => event.rules.requireFullRanking
            ? 'rank all options'
            : 'rank the options you support',
        BallotType.score => 'rate each option',
      };
}

extension on Widget {
  /// Sticky bottom voting bar over the scroll view.
  Widget withVoteBar(BuildContext context, VotingEvent event) {
    return Stack(
      children: [
        this,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _VoteBar(event: event),
        ),
      ],
    );
  }
}

class _VoteBar extends StatelessWidget {
  const _VoteBar({required this.event});

  final VotingEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSeeResults = event.canSeeResults(hasVoted: false);
    return Container(
      padding: EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border:
            Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (canSeeResults) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/e/${event.publicId}/results'),
                child: const Text('Results'),
              ),
            ),
            const SizedBox(width: Spacing.md),
          ],
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: event.isOpen
                  ? () => context.push('/e/${event.publicId}/vote')
                  : null,
              icon: const Icon(Icons.how_to_vote),
              label: Text(
                event.isOpen
                    ? 'Begin voting'
                    : event.isClosed
                        ? 'Voting closed'
                        : 'Not open yet',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidatePreviewCard extends StatelessWidget {
  const _CandidatePreviewCard({required this.candidate, required this.onTap});

  final Candidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.lg),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            children: [
              CandidateAvatar(candidate: candidate),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(candidate.name, style: theme.textTheme.titleMedium),
                    if (candidate.subtitle.isNotEmpty)
                      Text(
                        candidate.subtitle,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          tooltip: tooltip,
          onPressed: onTap,
        ),
      ),
    );
  }
}

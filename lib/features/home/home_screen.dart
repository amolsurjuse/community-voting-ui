import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/states.dart';
import '../../data/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/event.dart';
import '../auth/session_controller.dart';

final organizerEventsProvider = StreamProvider.autoDispose<List<VotingEvent>>(
  (ref) => ref.watch(eventRepositoryProvider).watchOrganizerEvents(),
);

/// Organizer home: greeting, actionable events first, compact analytics.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (!session.isAuthenticated) return const _SignedOutHome();

    final asyncEvents = ref.watch(organizerEventsProvider);
    final theme = Theme.of(context);
    final firstName = session.organizer!.fullName.split(' ').first;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(organizerEventsProvider),
          child: asyncEvents.when(
            loading: () => const SkeletonList(items: 4, itemHeight: 100),
            error: (_, __) => ErrorPanel(
              message: 'Could not load your events.',
              onRetry: () => ref.invalidate(organizerEventsProvider),
            ),
            data: (events) {
              final open =
                  events.where((e) => e.status == EventStatus.open).toList();
              final drafts = events.where((e) => e.isDraft).toList();
              final scheduled = events
                  .where((e) => e.status == EventStatus.scheduled)
                  .toList();
              final closed = events
                  .where((e) => e.status == EventStatus.closed)
                  .take(3)
                  .toList();
              final totalBallots =
                  open.fold<int>(0, (sum, e) => sum + e.totalBallots);

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Spacing.lg,
                        Spacing.xl,
                        Spacing.lg,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hi $firstName 👋',
                              style: theme.textTheme.headlineMedium),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            _greetingLine(open.length, totalBallots),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: Spacing.lg),
                          _StatsRow(
                            openCount: open.length,
                            ballots: totalBallots,
                            draftCount: drafts.length,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (events.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.campaign_outlined,
                        title: 'Create your first event',
                        message:
                            'Set up an award, election, or poll in a few minutes and share it with a link or QR code.',
                        actionLabel: 'Create event',
                        onAction: () => context.push('/create'),
                      ),
                    ),
                  if (open.isNotEmpty) ...[
                    const _Header('Active now'),
                    _EventSliver(events: open),
                  ],
                  if (scheduled.isNotEmpty) ...[
                    const _Header('Upcoming'),
                    _EventSliver(events: scheduled),
                  ],
                  if (drafts.isNotEmpty) ...[
                    const _Header('Drafts'),
                    _EventSliver(events: drafts, isDraft: true),
                  ],
                  if (closed.isNotEmpty) ...[
                    const _Header('Recently completed'),
                    _EventSliver(events: closed),
                  ],
                  const SliverToBoxAdapter(
                      child: SizedBox(height: Spacing.xxl)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _greetingLine(int openCount, int ballots) {
    if (openCount == 0) return 'Ready to start something new?';
    final events = openCount == 1 ? 'event' : 'events';
    return '$openCount live $events · ${Formatters.compactCount(ballots)} ballots so far';
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title);
  final String title;

  @override
  Widget build(BuildContext context) =>
      SliverToBoxAdapter(child: SectionHeader(title: title));
}

class _EventSliver extends StatelessWidget {
  const _EventSliver({required this.events, this.isDraft = false});

  final List<VotingEvent> events;
  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      sliver: SliverList.separated(
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
        itemBuilder: (context, i) {
          final event = events[i];
          return EventCard(
            event: event,
            showStatus: true,
            onTap: () => isDraft
                ? context.push('/create?eventId=${event.id}')
                : context.push('/manage/${event.id}'),
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.openCount,
    required this.ballots,
    required this.draftCount,
  });

  final int openCount;
  final int ballots;
  final int draftCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
            label: 'Live events', value: '$openCount', icon: Icons.podcasts),
        const SizedBox(width: Spacing.md),
        _StatCard(
          label: 'Ballots',
          value: Formatters.compactCount(ballots),
          icon: Icons.how_to_vote_outlined,
        ),
        const SizedBox(width: Spacing.md),
        _StatCard(
            label: 'Drafts', value: '$draftCount', icon: Icons.edit_outlined),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(height: Spacing.sm),
              Text(value, style: theme.textTheme.headlineSmall),
              Text(label, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home for visitors who haven't signed in — points to discover + register.
class _SignedOutHome extends StatelessWidget {
  const _SignedOutHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.indigo],
                  ),
                  borderRadius: BorderRadius.circular(Corners.xl),
                ),
                child: const Icon(Icons.how_to_vote,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                'Welcome to PulseVote',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Vote in events shared with you — no account needed. Create an organizer account to run your own.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.push('/auth/register'),
                child: const Text('Create organizer account'),
              ),
              const SizedBox(height: Spacing.md),
              OutlinedButton(
                onPressed: () => context.go('/discover'),
                child: const Text('Explore public events'),
              ),
              const SizedBox(height: Spacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

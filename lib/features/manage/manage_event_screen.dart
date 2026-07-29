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
import '../../domain/models/enums.dart';
import '../../domain/models/event.dart';
import '../event/share_sheet.dart';
import '../home/home_screen.dart';

/// Organizer event management: status, participation, quick actions.
class ManageEventScreen extends ConsumerWidget {
  const ManageEventScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvents = ref.watch(organizerEventsProvider);
    return asyncEvents.when(
      loading: () => const Scaffold(
        body: SafeArea(child: SkeletonList(items: 4, itemHeight: 90)),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: ErrorPanel(
          message: 'Could not load this event.',
          onRetry: () => ref.invalidate(organizerEventsProvider),
        ),
      ),
      data: (events) {
        final matches = events.where((e) => e.id == eventId);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.search_off,
              title: 'Event not found',
              message: 'This event may have been deleted.',
            ),
          );
        }
        return _ManageBody(event: matches.first);
      },
    );
  }
}

class _ManageBody extends ConsumerWidget {
  const _ManageBody({required this.event});

  final VotingEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.read(eventRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Event actions',
            onSelected: (action) async {
              switch (action) {
                case 'duplicate':
                  final copy = await repo.duplicate(event.id);
                  if (context.mounted) {
                    context.pushReplacement('/create?eventId=${copy.id}');
                  }
                case 'archive':
                  await repo.archive(event.id);
                  if (context.mounted) context.pop();
                case 'close':
                  final confirmed = await _confirmClose(context);
                  if (confirmed) await repo.close(event.id);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              if (event.isOpen)
                const PopupMenuItem(value: 'close', child: Text('Close voting')),
              if (event.isClosed)
                const PopupMenuItem(value: 'archive', child: Text('Archive')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            Row(
              children: [
                EventCoverArt(
                  coverSeed: event.coverSeed,
                  emoji: event.coverEmoji,
                  height: 64,
                  borderRadius: BorderRadius.circular(Corners.md),
                ),
                const SizedBox(width: Spacing.lg),
                Expanded(
                  child: Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.xs,
                    children: [
                      StatusBadge(status: event.status),
                      VerificationBadge(
                        level: event.verificationLevel, compact: true,
                      ),
                      VisibilityBadge(visibility: event.visibility),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Ballots',
                        value: Formatters.compactCount(event.totalBallots),
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: 'Options',
                        value: '${event.activeCandidates.length}',
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: event.isClosed ? 'Closed' : 'Closes',
                        value: event.endsAt == null
                            ? 'Manual'
                            : Formatters.countdown(event.endsAt)
                                .replaceFirst('Closes in ', ''),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            InfoRow(
              icon: Icons.schedule,
              label: 'Runs',
              value:
                  '${event.startsAt != null ? Formatters.dateTime(event.startsAt!) : 'On publish'} → '
                  '${event.endsAt != null ? Formatters.dateTime(event.endsAt!) : 'organizer close'}',
            ),
            InfoRow(
              icon: Icons.bar_chart,
              label: 'Results',
              value: event.resultVisibility.label,
            ),
            const SizedBox(height: Spacing.lg),
            FilledButton.icon(
              onPressed: () => showShareSheet(context, event),
              icon: const Icon(Icons.ios_share),
              label: const Text('Share event'),
            ),
            const SizedBox(height: Spacing.md),
            OutlinedButton.icon(
              onPressed: () =>
                  context.push('/manage/${event.id}/analytics'),
              icon: const Icon(Icons.insights_outlined),
              label: const Text('View analytics'),
            ),
            const SizedBox(height: Spacing.md),
            OutlinedButton.icon(
              onPressed: () => context.push('/e/${event.publicId}'),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('View as participant'),
            ),
            if (event.isOpen) ...[
              const SizedBox(height: Spacing.md),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                onPressed: () async {
                  final confirmed = await _confirmClose(context);
                  if (confirmed) await repo.close(event.id);
                },
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Close voting now'),
              ),
            ],
            const SizedBox(height: Spacing.xl),
            Text(
              'Options',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.md),
            for (final candidate in event.activeCandidates)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: Row(
                  children: [
                    CandidateAvatar(candidate: candidate, size: 36),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Text(candidate.name,
                          style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Future<bool> _confirmClose(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close voting?'),
        content: const Text(
          'No further ballots will be accepted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep open'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close voting'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.headlineSmall),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

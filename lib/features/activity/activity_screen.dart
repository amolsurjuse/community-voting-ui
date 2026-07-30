import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/states.dart';
import '../../data/providers.dart';
import '../../domain/models/activity.dart';
import '../auth/session_controller.dart';

final _activityProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(activityRepositoryProvider).watchActivity(),
);

/// Organizer activity feed with calm, actionable language.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final async = ref.watch(_activityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          TextButton(
            onPressed: session.isAuthenticated
                ? () => ref.read(activityRepositoryProvider).markAllRead()
                : null,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: SafeArea(
        child: !session.isAuthenticated
            ? EmptyState(
                icon: Icons.notifications_none,
                title: 'Sign in to see activity',
                message:
                    'Event updates, closing reminders and result notifications appear here.',
                actionLabel: 'Create account',
                onAction: () => context.push('/auth/register'),
              )
            : async.when(
                loading: () => const SkeletonList(items: 5, itemHeight: 76),
                error: (_, __) => ErrorPanel(
                  message: 'Could not load activity.',
                  onRetry: () => ref.invalidate(_activityProvider),
                ),
                data: (items) => items.isEmpty
                    ? const EmptyState(
                        icon: Icons.notifications_none,
                        title: 'All caught up',
                        message: 'New event activity will show up here.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(Spacing.lg),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: Spacing.sm),
                        itemBuilder: (context, i) =>
                            _ActivityTile(item: items[i]),
                      ),
              ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final ActivityItem item;

  (IconData, Color) get _style => switch (item.kind) {
        ActivityKind.eventPublished => (
            Icons.rocket_launch_outlined,
            AppColors.info
          ),
        ActivityKind.eventOpened => (
            Icons.play_circle_outline,
            AppColors.success
          ),
        ActivityKind.closingSoon => (Icons.timer_outlined, AppColors.warning),
        ActivityKind.eventClosed => (Icons.flag_outlined, AppColors.warning),
        ActivityKind.resultsFinalized => (
            Icons.emoji_events_outlined,
            AppColors.amber
          ),
        ActivityKind.verificationFailures => (
            Icons.gpp_maybe_outlined,
            AppColors.warning
          ),
        ActivityKind.suspiciousActivity => (
            Icons.gpp_maybe_outlined,
            AppColors.danger
          ),
        ActivityKind.exportReady => (
            Icons.download_done_outlined,
            AppColors.success
          ),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = _style;
    return Card(
      child: ListTile(
        onTap: item.eventId != null
            ? () => context.push('/manage/${item.eventId}')
            : null,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        title: Text(
          item.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: item.read ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${item.body}\n${Formatters.relative(item.occurredAt)}',
            style: theme.textTheme.bodySmall,
          ),
        ),
        isThreeLine: true,
        trailing: item.read
            ? null
            : Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}

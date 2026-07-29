import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/states.dart';
import '../event/share_sheet.dart';
import 'ballot_controller.dart';

/// Ballot accepted / already-voted confirmation with non-identifying receipt.
class ConfirmationScreen extends ConsumerWidget {
  const ConfirmationScreen({super.key, required this.publicId});

  final String publicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ballotFlowProvider(publicId));
    final theme = Theme.of(context);
    final event = state.event;
    final receipt = state.receipt;
    final alreadyVoted = state.phase == BallotPhase.alreadyVoted;

    if (event == null) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Nothing to confirm',
            message: 'Open an event to cast a ballot first.',
            actionLabel: 'Explore events',
            onAction: () => context.go('/discover'),
          ),
        ),
      );
    }

    final canSeeResults = event.canSeeResults(hasVoted: true);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.xl),
          children: [
            const SizedBox(height: Spacing.xxl),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1),
              duration: Motion.of(context, Motion.emphasized),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.how_to_reg,
                  color: AppColors.success,
                  size: 62,
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              alreadyVoted
                  ? 'You\'ve already voted in this event'
                  : 'Your ballot was accepted',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              event.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xl),
            if (receipt != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: Column(
                    children: [
                      Text('Receipt code', style: theme.textTheme.bodySmall),
                      const SizedBox(height: Spacing.sm),
                      SelectableText(
                        receipt.receiptCode,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          letterSpacing: 2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        'Accepted ${Formatters.dateTime(receipt.acceptedAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: Spacing.lg),
            const InfoCallout(
              icon: Icons.lock_outline,
              text: 'This receipt confirms your ballot was accepted. It does not '
                  'reveal your selections and cannot be linked back to them.',
            ),
            const SizedBox(height: Spacing.xl),
            if (canSeeResults)
              FilledButton.icon(
                onPressed: () =>
                    context.pushReplacement('/e/$publicId/results'),
                icon: const Icon(Icons.bar_chart),
                label: const Text('View results'),
              )
            else
              InfoCallout(
                icon: Icons.schedule,
                text: event.resultVisibility.explanation,
              ),
            const SizedBox(height: Spacing.md),
            OutlinedButton.icon(
              onPressed: () => showShareSheet(context, event),
              icon: const Icon(Icons.ios_share),
              label: const Text('Share this event'),
            ),
            const SizedBox(height: Spacing.md),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Return home'),
            ),
          ],
        ),
      ),
    );
  }
}

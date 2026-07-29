import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/states.dart';
import '../../data/providers.dart';
import '../../domain/models/analytics.dart';

final _analyticsProvider =
    FutureProvider.autoDispose.family<EventAnalytics, String>((ref, eventId) {
  return ref.watch(analyticsRepositoryProvider).summary(eventId);
});

/// Privacy-safe aggregate analytics. Never shows participant identity or
/// individual ballots.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_analyticsProvider(eventId));
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SafeArea(
        child: async.when(
          loading: () => const SkeletonList(items: 4, itemHeight: 110),
          error: (_, __) => ErrorPanel(
            message: 'Could not load analytics.',
            onRetry: () => ref.invalidate(_analyticsProvider(eventId)),
          ),
          data: (analytics) => _AnalyticsBody(analytics: analytics),
        ),
      ),
    );
  }
}

class _AnalyticsBody extends ConsumerWidget {
  const _AnalyticsBody({required this.analytics});

  final EventAnalytics analytics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Row(
          children: [
            _BigStat(
              label: 'Accepted ballots',
              value: Formatters.compactCount(analytics.acceptedBallots),
              icon: Icons.how_to_vote_outlined,
            ),
            const SizedBox(width: Spacing.md),
            _BigStat(
              label: 'Verification rate',
              value: Formatters.percent(analytics.verificationCompletionRate
                  .clamp(0, 1)
                  .toDouble()),
              icon: Icons.verified_user_outlined,
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            _BigStat(
              label: 'Submission rate',
              value: Formatters.percent(
                analytics.submissionRate.clamp(0, 1).toDouble(),
              ),
              icon: Icons.task_alt,
            ),
            const SizedBox(width: Spacing.md),
            _BigStat(
              label: 'Failed verifications',
              value: '${analytics.failedVerificationAttempts}',
              icon: Icons.gpp_maybe_outlined,
            ),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        Text('Participation over time', style: theme.textTheme.titleMedium),
        const SizedBox(height: Spacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: SizedBox(
              height: 120,
              child: _BarSparkline(values: analytics.participationByHour),
            ),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text('Ballots per hour, last 24 hours',
            style: theme.textTheme.labelSmall),
        if (analytics.suspiciousIndicators.isNotEmpty) ...[
          const SizedBox(height: Spacing.xl),
          Text('Suspicious activity', style: theme.textTheme.titleMedium),
          const SizedBox(height: Spacing.md),
          for (final indicator in analytics.suspiciousIndicators)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: InfoCallout(
                icon: Icons.gpp_maybe_outlined,
                tone: CalloutTone.warning,
                text: indicator,
              ),
            ),
          Text(
            'Indicators are heuristics, not proof of fraud. Review them before acting.',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (analytics.platformSplit.isNotEmpty) ...[
          const SizedBox(height: Spacing.xl),
          Text('Platforms', style: theme.textTheme.titleMedium),
          const SizedBox(height: Spacing.sm),
          for (final entry in analytics.platformSplit.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(entry.key)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Corners.pill),
                      child: LinearProgressIndicator(
                        value: entry.value,
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Text(Formatters.percent(entry.value)),
                ],
              ),
            ),
          Text(
            'Shown only when the sample is large enough to be privacy-safe.',
            style: theme.textTheme.labelSmall,
          ),
        ],
        const SizedBox(height: Spacing.xl),
        OutlinedButton.icon(
          onPressed: () async {
            await ref
                .read(analyticsRepositoryProvider)
                .requestExport(analytics.eventId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Export requested — you\'ll get a notification when it\'s ready.',
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export results (CSV)'),
        ),
        const SizedBox(height: Spacing.lg),
        const InfoCallout(
          icon: Icons.lock_outline,
          text: 'Analytics are aggregated. Individual participants and their ballot selections are never shown.',
        ),
        const SizedBox(height: Spacing.xl),
      ],
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({
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
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
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

/// Lightweight bar sparkline — no chart package required.
class _BarSparkline extends StatelessWidget {
  const _BarSparkline({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final peak = max(1, values.fold<int>(0, max));
    return Semantics(
      label:
          'Participation chart: peak ${values.fold<int>(0, max)} ballots in one hour',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final value in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: FractionallySizedBox(
                  heightFactor: (value / peak).clamp(0.03, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: value == peak ? 1 : 0.55),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

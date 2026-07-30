import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/candidate_avatar.dart';
import '../../../core/widgets/common.dart';
import '../../event/share_sheet.dart';
import '../create_wizard_controller.dart';

/// Step 6: participant-eye preview + publish.
class PreviewStep extends StatelessWidget {
  const PreviewStep({super.key, required this.state, required this.controller});

  final WizardState state;
  final CreateWizardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = state.draft;
    final published = state.status == WizardStatus.published;

    if (published) return _PublishedView(state: state);

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Text(
          'This is what participants will see',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: Spacing.md),
        // Miniature participant-view preview card.
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventCoverArt(
                coverSeed: draft.coverSeed,
                emoji: draft.coverEmoji,
                height: 140,
                borderRadius: BorderRadius.zero,
              ),
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.xs,
                      children: [
                        VerificationBadge(level: draft.verificationLevel),
                        VisibilityBadge(visibility: draft.visibility),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      draft.title.isEmpty ? 'Untitled event' : draft.title,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'Organized by ${draft.organizerName}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (draft.shortDescription.isNotEmpty) ...[
                      const SizedBox(height: Spacing.md),
                      Text(draft.shortDescription,
                          style: theme.textTheme.bodyMedium),
                    ],
                    const Divider(height: Spacing.xl),
                    InfoRow(
                      icon: Icons.how_to_vote_outlined,
                      label: 'Voting',
                      value: draft.rules.ballotType.label,
                    ),
                    InfoRow(
                      icon: Icons.timer_outlined,
                      label: 'Deadline',
                      value: draft.endsAt == null
                          ? 'Open until you close it'
                          : Formatters.dateTime(draft.endsAt!),
                    ),
                    InfoRow(
                      icon: Icons.bar_chart,
                      label: 'Results',
                      value: draft.resultVisibility.label,
                    ),
                    const SizedBox(height: Spacing.md),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: draft.activeCandidates.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: Spacing.sm),
                        itemBuilder: (context, i) => CandidateAvatar(
                          candidate: draft.activeCandidates[i],
                          size: 48,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        _ChecklistTile(
          label: 'Title and description',
          done: state.basicsComplete,
        ),
        _ChecklistTile(
          label: 'At least two options',
          done: state.candidatesComplete,
        ),
        _ChecklistTile(label: 'Valid voting rules', done: state.rulesComplete),
        if (state.isIndefinite)
          const Padding(
            padding: EdgeInsets.only(top: Spacing.sm),
            child: InfoCallout(
              tone: CalloutTone.warning,
              icon: Icons.hourglass_empty,
              text:
                  'No end date set — this event will run until you close it manually.',
            ),
          ),
        const SizedBox(height: Spacing.xl),
        FilledButton.icon(
          onPressed:
              state.readyToPublish && state.status != WizardStatus.publishing
                  ? () async {
                      final ok = await controller.publish();
                      if (ok) Haptics.success();
                    }
                  : null,
          icon: state.status == WizardStatus.publishing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Icon(Icons.rocket_launch_outlined),
          label: Text(
            state.status == WizardStatus.publishing
                ? 'Publishing…'
                : draft.startsAt != null &&
                        draft.startsAt!.isAfter(DateTime.now())
                    ? 'Schedule event'
                    : 'Publish event',
          ),
        ),
        const SizedBox(height: Spacing.xxl),
      ],
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: done ? AppColors.success : theme.colorScheme.outline,
          ),
          const SizedBox(width: Spacing.md),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _PublishedView extends StatelessWidget {
  const _PublishedView({required this.state});

  final WizardState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = state.draft;
    return ListView(
      padding: const EdgeInsets.all(Spacing.xl),
      children: [
        const SizedBox(height: Spacing.xxl),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1),
          duration: Motion.of(context, Motion.emphasized),
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child:
              const Icon(Icons.celebration, size: 88, color: AppColors.coral),
        ),
        const SizedBox(height: Spacing.xl),
        Text(
          'Your event is live!',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Share the link so people can start voting.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.xl),
        FilledButton.icon(
          onPressed: () => showShareSheet(context, event),
          icon: const Icon(Icons.ios_share),
          label: const Text('Share event'),
        ),
        const SizedBox(height: Spacing.md),
        OutlinedButton(
          onPressed: () => context.go('/manage/${event.id}'),
          child: const Text('Manage event'),
        ),
        const SizedBox(height: Spacing.md),
        TextButton(
          onPressed: () => context.go('/home'),
          child: const Text('Back to home'),
        ),
      ],
    );
  }
}

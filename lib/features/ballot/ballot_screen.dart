import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/candidate_avatar.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/states.dart';
import '../../domain/models/ballot.dart';
import '../../domain/models/candidate.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/event.dart';
import '../auth/widgets/otp_field.dart';
import '../event/candidate_sheet.dart';
import 'ballot_controller.dart';
import 'ballot_review_sheet.dart';

/// The core voting experience: selection UI per ballot type, progress,
/// validation, review and explicit submission states.
class BallotScreen extends ConsumerWidget {
  const BallotScreen({super.key, required this.publicId});

  final String publicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ballotFlowProvider(publicId));
    final controller = ref.read(ballotFlowProvider(publicId).notifier);
    final event = state.event;

    return PopScope(
      // Warn only when leaving would discard real selections.
      canPop: !state.hasUnsavedSelections,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave without voting?'),
            content: const Text(
              'Your selections have not been submitted and will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep voting'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            event?.title ?? 'Ballot',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(child: _body(context, state, controller)),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    BallotFlowState state,
    BallotFlowController controller,
  ) {
    switch (state.phase) {
      case BallotPhase.loading:
        return const SkeletonList(items: 5, itemHeight: 84);
      case BallotPhase.loadError:
        return ErrorPanel(
          message: state.message ?? 'Something went wrong.',
          onRetry: controller.load,
        );
      case BallotPhase.eventNotFound:
        return EmptyState(
          icon: Icons.link_off,
          title: 'Event not found',
          message: 'This link may be invalid or expired.',
          actionLabel: 'Explore public events',
          onAction: () => context.go('/discover'),
        );
      case BallotPhase.needsVerification:
      case BallotPhase.verifying:
        return _VerificationGate(state: state, controller: controller);
      case BallotPhase.building:
        return _BallotBuilder(state: state, controller: controller);
      case BallotPhase.submitting:
        return const _SubmittingView(
          title: 'Submitting your ballot…',
          message:
              'Please keep the app open. Do not submit twice — we\'ll confirm as soon as it\'s accepted.',
        );
      case BallotPhase.confirmingOutcome:
        return _ConfirmingOutcomeView(controller: controller);
      case BallotPhase.accepted:
      case BallotPhase.alreadyVoted:
        // Confirmation screen renders the receipt.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.pushReplacement('/e/$publicId/confirmation');
          }
        });
        return const SizedBox.shrink();
      case BallotPhase.eventClosed:
        return EmptyState(
          icon: Icons.flag_outlined,
          title: 'Voting has closed',
          message:
              'This event is no longer accepting ballots. Results may be available on the event page.',
          actionLabel: 'Back to event',
          onAction: () => context.go('/e/$publicId'),
        );
      case BallotPhase.verificationExpired:
        return EmptyState(
          icon: Icons.timer_off_outlined,
          title: 'Verification expired',
          message: state.message ?? 'Verify again to continue.',
          actionLabel: 'Verify again',
          onAction: controller.load,
        );
      case BallotPhase.invalid:
        return ErrorPanel(
          title: 'Ballot not accepted',
          message: state.message ?? 'The ballot was invalid.',
          onRetry: controller.load,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Verification gate (phone-verified events)
// ---------------------------------------------------------------------------

class _VerificationGate extends StatelessWidget {
  const _VerificationGate({required this.state, required this.controller});

  final BallotFlowState state;
  final BallotFlowController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(Spacing.xl),
      children: [
        Icon(Icons.sms_outlined, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: Spacing.lg),
        Text('Quick phone check', style: theme.textTheme.headlineSmall),
        const SizedBox(height: Spacing.sm),
        Text(
          'This event requires phone verification: one ballot per verified '
          'number. Enter the 6-digit code we texted you. No account is created '
          'and your number is never shown to the organizer.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.xl),
        OtpField(
          enabled: state.phase != BallotPhase.verifying,
          onCompleted: controller.completeVerification,
        ),
        if (state.phase == BallotPhase.verifying) ...[
          const SizedBox(height: Spacing.xl),
          const Center(child: CircularProgressIndicator()),
        ],
        if (state.message != null) ...[
          const SizedBox(height: Spacing.lg),
          InfoCallout(
            text: state.message!,
            icon: Icons.error_outline,
            tone: CalloutTone.danger,
          ),
        ],
        const SizedBox(height: Spacing.lg),
        const InfoCallout(
          text:
              'Development build: any 6-digit code ending in an even digit works.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ballot builder
// ---------------------------------------------------------------------------

class _BallotBuilder extends StatelessWidget {
  const _BallotBuilder({required this.state, required this.controller});

  final BallotFlowState state;
  final BallotFlowController controller;

  @override
  Widget build(BuildContext context) {
    final event = state.event!;
    final draft = state.draft!;
    final validation = state.validation;
    final candidates = event.activeCandidates;
    final isRanked = event.rules.ballotType == BallotType.rankedChoice;

    return Column(
      children: [
        _BallotHeader(event: event, selectedCount: draft.selections.length),
        if (state.message != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.lg, 0, Spacing.lg, Spacing.sm),
            child: InfoCallout(
              text: state.message!,
              icon: Icons.info_outline,
              tone: CalloutTone.warning,
            ),
          ),
        Expanded(
          child: isRanked
              ? _RankedList(
                  event: event,
                  selections: draft.selections,
                  controller: controller,
                )
              : _ChoiceList(
                  event: event,
                  candidates: candidates,
                  selections: draft.selections,
                  controller: controller,
                ),
        ),
        _BottomActionBar(
          validation: validation,
          allowReview: event.rules.allowReview,
          onReview: () => showBallotReviewSheet(
            context,
            state: state,
            onSubmit: controller.submit,
          ),
          onSubmit: controller.submit,
        ),
      ],
    );
  }
}

class _BallotHeader extends StatelessWidget {
  const _BallotHeader({required this.event, required this.selectedCount});

  final VotingEvent event;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rules = event.rules;
    final (instruction, counter) = switch (rules.ballotType) {
      BallotType.singleChoice => (
          'Select one option',
          selectedCount == 1 ? '1 selected' : 'None selected'
        ),
      BallotType.multipleChoice => (
          'Select ${rules.minSelections == rules.maxSelections ? rules.minSelections : '${rules.minSelections}–${rules.maxSelections}'} options',
          '$selectedCount of ${rules.maxSelections} selected',
        ),
      BallotType.rankedChoice => (
          'Tap to rank in order of preference, then drag to adjust',
          '$selectedCount ranked',
        ),
      BallotType.score => ('', ''),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(instruction, style: theme.textTheme.titleMedium)),
              AnimatedSwitcher(
                duration: Motion.of(context, Motion.fast),
                child: Container(
                  key: ValueKey(counter),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Corners.pill),
                  ),
                  child: Text(
                    counter,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (rules.ballotType == BallotType.rankedChoice) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              'If your top choice is eliminated, your ballot can count toward '
              'your next choice. The exact counting method is shown on the '
              'results page.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceList extends StatelessWidget {
  const _ChoiceList({
    required this.event,
    required this.candidates,
    required this.selections,
    required this.controller,
  });

  final VotingEvent event;
  final List<Candidate> candidates;
  final List<String> selections;
  final BallotFlowController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.lg),
      itemCount: candidates.length,
      separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
      itemBuilder: (context, i) {
        final candidate = candidates[i];
        final selected = selections.contains(candidate.id);
        final isSingle = event.rules.ballotType == BallotType.singleChoice;
        return _SelectableCandidateCard(
          candidate: candidate,
          selected: selected,
          selectionIcon: isSingle
              ? (selected ? Icons.radio_button_checked : Icons.radio_button_off)
              : (selected ? Icons.check_box : Icons.check_box_outline_blank),
          onTap: () {
            Haptics.selection();
            controller.toggleSelection(candidate.id);
          },
          onInfo: () => showCandidateSheet(
            context,
            candidate,
            actionLabel: selected ? 'Remove selection' : 'Select',
            onAction: () => controller.toggleSelection(candidate.id),
          ),
        );
      },
    );
  }
}

class _SelectableCandidateCard extends StatelessWidget {
  const _SelectableCandidateCard({
    required this.candidate,
    required this.selected,
    required this.selectionIcon,
    required this.onTap,
    required this.onInfo,
  });

  final Candidate candidate;
  final bool selected;
  final IconData selectionIcon;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label:
          '${candidate.name}${candidate.subtitle.isNotEmpty ? ', ${candidate.subtitle}' : ''}',
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.fast),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Corners.lg),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
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
                        Text(candidate.name,
                            style: theme.textTheme.titleMedium),
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
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
                    tooltip: 'About ${candidate.name}',
                    onPressed: onInfo,
                  ),
                  Icon(
                    selectionIcon,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankedList extends StatelessWidget {
  const _RankedList({
    required this.event,
    required this.selections,
    required this.controller,
  });

  final VotingEvent event;
  final List<String> selections;
  final BallotFlowController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byId = {for (final c in event.activeCandidates) c.id: c};
    final ranked = [for (final id in selections) byId[id]!];
    final unranked = [
      for (final c in event.activeCandidates)
        if (!selections.contains(c.id)) c,
    ];

    return CustomScrollView(
      slivers: [
        if (ranked.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child:
                        Text('Your ranking', style: theme.textTheme.titleSmall),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Haptics.light();
                      controller.resetRanking();
                    },
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          sliver: SliverReorderableList(
            itemCount: ranked.length,
            onReorder: (oldIndex, newIndex) {
              Haptics.selection();
              controller.reorderRanking(oldIndex, newIndex);
            },
            itemBuilder: (context, i) {
              final candidate = ranked[i];
              return Padding(
                key: ValueKey(candidate.id),
                padding: const EdgeInsets.only(bottom: Spacing.md),
                child: _RankedCard(
                  candidate: candidate,
                  rank: i + 1,
                  index: i,
                  onRemove: () => controller.toggleSelection(candidate.id),
                ),
              );
            },
          ),
        ),
        if (unranked.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.lg, Spacing.md, Spacing.lg, Spacing.sm),
            sliver: SliverToBoxAdapter(
              child: Text(
                ranked.isEmpty
                    ? 'Tap options in your order of preference'
                    : 'Not yet ranked',
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.lg, 0, Spacing.lg, Spacing.lg),
            sliver: SliverList.separated(
              itemCount: unranked.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
              itemBuilder: (context, i) {
                final candidate = unranked[i];
                return _SelectableCandidateCard(
                  candidate: candidate,
                  selected: false,
                  selectionIcon: Icons.add_circle_outline,
                  onTap: () {
                    Haptics.selection();
                    controller.toggleSelection(candidate.id);
                  },
                  onInfo: () => showCandidateSheet(
                    context,
                    candidate,
                    actionLabel: 'Rank next',
                    onAction: () => controller.toggleSelection(candidate.id),
                  ),
                );
              },
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: Spacing.lg)),
      ],
    );
  }
}

class _RankedCard extends StatelessWidget {
  const _RankedCard({
    required this.candidate,
    required this.rank,
    required this.index,
    required this.onRemove,
  });

  final Candidate candidate;
  final int rank;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Rank $rank: ${candidate.name}. Drag to reorder.',
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Corners.lg),
          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            CandidateAvatar(candidate: candidate, size: 40),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                candidate.name,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              tooltip: 'Remove ${candidate.name} from ranking',
              onPressed: onRemove,
            ),
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.validation,
    required this.allowReview,
    required this.onReview,
    required this.onSubmit,
  });

  final BallotValidation validation;
  final bool allowReview;
  final VoidCallback onReview;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = validation.isValid;
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border:
            Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isValid)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Text(
                validation.message,
                style: theme.textTheme.bodySmall,
              ),
            ),
          FilledButton(
            onPressed: isValid ? (allowReview ? onReview : onSubmit) : null,
            child: Text(allowReview ? 'Review ballot' : 'Submit ballot'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Submission states
// ---------------------------------------------------------------------------

class _SubmittingView extends StatelessWidget {
  const _SubmittingView({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: Spacing.xl),
            Text(title,
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: Spacing.sm),
            Text(
              message,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmingOutcomeView extends StatelessWidget {
  const _ConfirmingOutcomeView({required this.controller});

  final BallotFlowController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_tethering, size: 48, color: AppColors.info),
            const SizedBox(height: Spacing.xl),
            Text(
              'We are confirming whether your ballot was accepted.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'The connection was interrupted during submission. Your ballot '
              'was not lost — retrying is safe and will never create a '
              'duplicate.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xl),
            FilledButton.icon(
              onPressed: controller.confirmOutcome,
              icon: const Icon(Icons.refresh),
              label: const Text('Check status'),
            ),
          ],
        ),
      ),
    );
  }
}

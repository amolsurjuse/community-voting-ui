import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../domain/models/enums.dart';
import '../create_wizard_controller.dart';

/// Step 3: ballot type + type-specific rules. Locked once voting opens.
class RulesStep extends StatelessWidget {
  const RulesStep({super.key, required this.state, required this.controller});

  final WizardState state;
  final CreateWizardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = state.draft;
    final rules = draft.rules;
    final locked = state.settingsLocked;
    final candidateCount = draft.activeCandidates.length;

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        if (locked)
          const Padding(
            padding: EdgeInsets.only(bottom: Spacing.lg),
            child: InfoCallout(
              icon: Icons.lock_outline,
              text: 'Voting rules are locked while the event is open, so every ballot is counted the same way.',
            ),
          ),
        Text('How do people vote?', style: theme.textTheme.titleMedium),
        const SizedBox(height: Spacing.md),
        for (final type in const [
          BallotType.singleChoice,
          BallotType.multipleChoice,
          BallotType.rankedChoice,
          BallotType.score,
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: _BallotTypeCard(
              type: type,
              selected: rules.ballotType == type,
              enabled: !locked && type != BallotType.score,
              onTap: () => controller.updateDraft(
                draft.copyWith(rules: rules.copyWith(ballotType: type)),
              ),
            ),
          ),
        const SizedBox(height: Spacing.md),
        if (rules.ballotType == BallotType.multipleChoice) ...[
          Text('Selection limits', style: theme.textTheme.titleMedium),
          const SizedBox(height: Spacing.sm),
          _CounterRow(
            label: 'Minimum selections',
            value: rules.minSelections,
            min: 1,
            max: rules.maxSelections,
            enabled: !locked,
            onChanged: (v) => controller.updateDraft(
              draft.copyWith(rules: rules.copyWith(minSelections: v)),
            ),
          ),
          _CounterRow(
            label: 'Maximum selections',
            value: rules.maxSelections,
            min: rules.minSelections,
            max: candidateCount > 0 ? candidateCount : 10,
            enabled: !locked,
            onChanged: (v) => controller.updateDraft(
              draft.copyWith(rules: rules.copyWith(maxSelections: v)),
            ),
          ),
          if (!state.rulesComplete)
            const InfoCallout(
              icon: Icons.error_outline,
              tone: CalloutTone.warning,
              text: 'Selection limits must fit within the number of options.',
            ),
        ],
        if (rules.ballotType == BallotType.rankedChoice) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Require ranking every option'),
            subtitle: const Text(
              'Off: participants may rank only the options they support.',
            ),
            value: rules.requireFullRanking,
            onChanged: locked
                ? null
                : (v) => controller.updateDraft(
                      draft.copyWith(
                        rules: rules.copyWith(requireFullRanking: v),
                      ),
                    ),
          ),
          InfoCallout(
            icon: Icons.functions,
            text: 'Counting method shown to participants: ${rules.rankedAlgorithm}. '
                'Tie-breaking: ${rules.tieBreakPolicy}',
          ),
          const SizedBox(height: Spacing.md),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ballot review before submission'),
          subtitle: const Text('Participants confirm a summary before submitting.'),
          value: rules.allowReview,
          onChanged: locked
              ? null
              : (v) => controller.updateDraft(
                    draft.copyWith(rules: rules.copyWith(allowReview: v)),
                  ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Allow changes before submission'),
          subtitle: const Text(
            'Selections can always be edited until the ballot is submitted. '
            'Accepted ballots can never be changed.',
          ),
          value: rules.allowChangeBeforeSubmit,
          onChanged: locked
              ? null
              : (v) => controller.updateDraft(
                    draft.copyWith(
                      rules: rules.copyWith(allowChangeBeforeSubmit: v),
                    ),
                  ),
        ),
      ],
    );
  }
}

class _BallotTypeCard extends StatelessWidget {
  const _BallotTypeCard({
    required this.type,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final BallotType type;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (type) {
      BallotType.singleChoice => Icons.radio_button_checked,
      BallotType.multipleChoice => Icons.check_box,
      BallotType.rankedChoice => Icons.format_list_numbered,
      BallotType.score => Icons.star_half,
    };
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
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
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(Corners.lg),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Row(
                children: [
                  Icon(icon,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: Spacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(type.label, style: theme.textTheme.titleSmall),
                            if (type == BallotType.score) ...[
                              const SizedBox(width: Spacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary
                                      .withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(Corners.pill),
                                ),
                                child: Text(
                                  'Coming soon',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(type.explanation,
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          IconButton.outlined(
            onPressed:
                enabled && value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
            tooltip: 'Decrease $label',
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton.outlined(
            onPressed:
                enabled && value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
            tooltip: 'Increase $label',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../domain/models/enums.dart';
import '../create_wizard_controller.dart';

/// Step 4: visibility + participant verification with an honest
/// convenience/privacy/cost/fraud-resistance trade-off display.
class AccessStep extends StatelessWidget {
  const AccessStep({super.key, required this.state, required this.controller});

  final WizardState state;
  final CreateWizardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = state.draft;
    final locked = state.settingsLocked;

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Text('Who can find this event?', style: theme.textTheme.titleMedium),
        const SizedBox(height: Spacing.md),
        for (final visibility in EventVisibility.values)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: _OptionCard(
              title: visibility.label,
              subtitle: visibility.explanation,
              icon: switch (visibility) {
                EventVisibility.public => Icons.public,
                EventVisibility.unlisted => Icons.link,
                EventVisibility.private => Icons.lock_outline,
              },
              selected: draft.visibility == visibility,
              enabled: !locked,
              onTap: () => controller
                  .updateDraft(draft.copyWith(visibility: visibility)),
            ),
          ),
        const SizedBox(height: Spacing.lg),
        Text('How are voters verified?', style: theme.textTheme.titleMedium),
        const SizedBox(height: Spacing.xs),
        Text(
          'Stronger verification means fewer duplicate ballots but more friction for participants.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: Spacing.md),
        for (final level in VerificationLevel.values)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: _VerificationCard(
              level: level,
              selected: draft.verificationLevel == level,
              enabled: !locked && level != VerificationLevel.organizerApproval,
              onTap: () => controller
                  .updateDraft(draft.copyWith(verificationLevel: level)),
            ),
          ),
        if (draft.verificationLevel == VerificationLevel.basicInstall ||
            draft.verificationLevel == VerificationLevel.verifiedInstall)
          const InfoCallout(
            icon: Icons.info_outline,
            text:
                'One ballot is allowed per verified app installation for this '
                'event. This does not guarantee one ballot per individual person.',
          ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                        Text(title, style: theme.textTheme.titleSmall),
                        Text(subtitle, style: theme.textTheme.bodySmall),
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

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.level,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final VerificationLevel level;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  /// (convenience, fraud resistance) on a 1–3 scale, honest about trade-offs.
  (int, int) get _tradeoff => switch (level) {
        VerificationLevel.basicInstall => (3, 1),
        VerificationLevel.verifiedInstall => (3, 2),
        VerificationLevel.phone => (2, 3),
        VerificationLevel.invitation => (2, 3),
        VerificationLevel.organizerApproval => (1, 3),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (convenience, fraud) = _tradeoff;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(level.label,
                            style: theme.textTheme.titleSmall),
                      ),
                      if (level == VerificationLevel.organizerApproval)
                        Text('Coming soon', style: theme.textTheme.labelSmall)
                      else if (selected)
                        Icon(Icons.check_circle,
                            color: theme.colorScheme.primary),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(level.summary, style: theme.textTheme.bodySmall),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      _MeterLabel(label: 'Ease', value: convenience),
                      const SizedBox(width: Spacing.lg),
                      _MeterLabel(label: 'Fraud resistance', value: fraud),
                    ],
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

class _MeterLabel extends StatelessWidget {
  const _MeterLabel({required this.label, required this.value});

  final String label;
  final int value; // 1–3

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value of 3',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ', style: theme.textTheme.labelSmall),
          for (var i = 1; i <= 3; i++)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Container(
                width: 12,
                height: 5,
                decoration: BoxDecoration(
                  color: i <= value
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

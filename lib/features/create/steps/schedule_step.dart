import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../domain/models/enums.dart';
import '../create_wizard_controller.dart';

/// Step 5: start/end times and result visibility.
class ScheduleStep extends StatelessWidget {
  const ScheduleStep({super.key, required this.state, required this.controller});

  final WizardState state;
  final CreateWizardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = state.draft;
    final locked = state.settingsLocked;
    final startsImmediately = draft.startsAt == null;

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Text('When does voting run?', style: theme.textTheme.titleMedium),
        const SizedBox(height: Spacing.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Start immediately on publish'),
          value: startsImmediately,
          onChanged: locked
              ? null
              : (immediate) => controller.updateDraft(
                    draft.copyWith(
                      clearStartsAt: immediate,
                      startsAt: immediate
                          ? null
                          : DateTime.now().add(const Duration(days: 1)),
                    ),
                  ),
        ),
        if (!startsImmediately)
          _DateTimeTile(
            label: 'Starts',
            value: draft.startsAt!,
            enabled: !locked,
            onChanged: (dt) =>
                controller.updateDraft(draft.copyWith(startsAt: dt)),
          ),
        const Divider(height: Spacing.xl),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Set an end date'),
          subtitle: const Text('Off: you close the event manually.'),
          value: draft.endsAt != null,
          onChanged: locked
              ? null
              : (hasEnd) => controller.updateDraft(
                    draft.copyWith(
                      clearEndsAt: !hasEnd,
                      endsAt: hasEnd
                          ? DateTime.now().add(const Duration(days: 7))
                          : null,
                    ),
                  ),
        ),
        if (draft.endsAt != null)
          _DateTimeTile(
            label: 'Ends',
            value: draft.endsAt!,
            enabled: !locked,
            onChanged: (dt) =>
                controller.updateDraft(draft.copyWith(endsAt: dt)),
          ),
        if (state.isIndefinite)
          const Padding(
            padding: EdgeInsets.only(top: Spacing.sm),
            child: InfoCallout(
              icon: Icons.hourglass_empty,
              tone: CalloutTone.warning,
              text: 'Without an end date this event runs indefinitely until you '
                  'close it. Participants will see "no deadline", which can '
                  'reduce urgency to vote.',
            ),
          ),
        if (draft.endsAt != null) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            'Duration: ${_durationSummary(draft.startsAt, draft.endsAt!)} · times shown in ${draft.timeZone.toLowerCase()}',
            style: theme.textTheme.bodySmall,
          ),
        ],
        const Divider(height: Spacing.xxl),
        Text('When are results visible?', style: theme.textTheme.titleMedium),
        const SizedBox(height: Spacing.md),
        for (final visibility in ResultVisibility.values)
          RadioListTile<ResultVisibility>(
            contentPadding: EdgeInsets.zero,
            title: Text(visibility.label),
            subtitle: Text(visibility.explanation),
            value: visibility,
            groupValue: draft.resultVisibility,
            onChanged: locked
                ? null
                : (v) {
                    if (v != null) {
                      controller
                          .updateDraft(draft.copyWith(resultVisibility: v));
                    }
                  },
          ),
        const SizedBox(height: Spacing.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hide counts below 10 ballots'),
          subtitle: const Text(
            'Protects early-voter privacy in small events.',
          ),
          value: draft.minResultThreshold > 0,
          onChanged: locked
              ? null
              : (v) => controller.updateDraft(
                    draft.copyWith(minResultThreshold: v ? 10 : 0),
                  ),
        ),
      ],
    );
  }

  static String _durationSummary(DateTime? start, DateTime end) {
    final from = start ?? DateTime.now();
    final diff = end.difference(from);
    if (diff.inDays >= 1) return '${diff.inDays} days';
    if (diff.inHours >= 1) return '${diff.inHours} hours';
    return '${diff.inMinutes} minutes';
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event),
      title: Text(label),
      subtitle: Text(Formatters.dateTime(value)),
      trailing: const Icon(Icons.edit_outlined, size: 18),
      enabled: enabled,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        onChanged(DateTime(
          date.year, date.month, date.day,
          time?.hour ?? value.hour, time?.minute ?? value.minute,
        ));
      },
    );
  }
}

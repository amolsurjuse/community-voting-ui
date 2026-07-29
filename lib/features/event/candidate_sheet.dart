import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/candidate_avatar.dart';
import '../../core/widgets/common.dart';
import '../../domain/models/candidate.dart';

/// Candidate detail bottom sheet. Shows organizer-provided information only —
/// never private notes or contact details.
Future<void> showCandidateSheet(
  BuildContext context,
  Candidate candidate, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return showAppSheet(
    context,
    child: _CandidateSheet(
      candidate: candidate,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );
}

class _CandidateSheet extends StatelessWidget {
  const _CandidateSheet({
    required this.candidate,
    this.actionLabel,
    this.onAction,
  });

  final Candidate candidate;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CandidateAvatar(candidate: candidate, size: 64),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(candidate.name, style: theme.textTheme.headlineSmall),
                    if (candidate.subtitle.isNotEmpty)
                      Text(candidate.subtitle, style: theme.textTheme.bodySmall),
                    if (candidate.organization.isNotEmpty)
                      Text(
                        candidate.organization,
                        style: theme.textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (candidate.description.isNotEmpty) ...[
            const SizedBox(height: Spacing.xl),
            Text(candidate.description, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: Spacing.xl),
          if (actionLabel != null)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction?.call();
              },
              child: Text(actionLabel!),
            )
          else
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }
}

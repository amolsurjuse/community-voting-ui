import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/candidate_avatar.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/states.dart';
import '../../../domain/models/candidate.dart';
import '../create_wizard_controller.dart';

/// Step 2: add, edit, reorder, duplicate and remove options.
class CandidatesStep extends StatelessWidget {
  const CandidatesStep({
    super.key,
    required this.state,
    required this.controller,
  });

  final WizardState state;
  final CreateWizardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidates = state.draft.activeCandidates;
    final locked = state.settingsLocked;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${candidates.length} option${candidates.length == 1 ? '' : 's'} · at least 2 required',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed:
                    locked ? null : () => _showEditor(context, controller),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        if (locked)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: InfoCallout(
              icon: Icons.lock_outline,
              text:
                  'Voting has started, so options are locked to keep the ballot fair.',
            ),
          ),
        Expanded(
          child: candidates.isEmpty
              ? EmptyState(
                  icon: Icons.people_outline,
                  title: 'No options yet',
                  message:
                      'Add the candidates, entries, or ideas people will vote on. You can reorder them any time before publishing.',
                  actionLabel: 'Add first option',
                  onAction: () => _showEditor(context, controller),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    0,
                    Spacing.lg,
                    Spacing.lg,
                  ),
                  itemCount: candidates.length,
                  onReorder: locked
                      ? (_, __) {}
                      : (oldIndex, newIndex) {
                          Haptics.selection();
                          controller.reorderCandidates(oldIndex, newIndex);
                        },
                  itemBuilder: (context, i) {
                    final candidate = candidates[i];
                    return Padding(
                      key: ValueKey(candidate.id),
                      padding: const EdgeInsets.only(bottom: Spacing.md),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: Spacing.md,
                            vertical: Spacing.xs,
                          ),
                          leading:
                              CandidateAvatar(candidate: candidate, size: 44),
                          title: Text(candidate.name,
                              style: theme.textTheme.titleSmall),
                          subtitle: candidate.subtitle.isNotEmpty
                              ? Text(candidate.subtitle,
                                  maxLines: 1, overflow: TextOverflow.ellipsis)
                              : null,
                          onTap: () => _showEditor(
                            context,
                            controller,
                            existing: candidate,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PopupMenuButton<String>(
                                tooltip: 'Options for ${candidate.name}',
                                onSelected: (action) {
                                  switch (action) {
                                    case 'edit':
                                      _showEditor(
                                        context,
                                        controller,
                                        existing: candidate,
                                      );
                                    case 'duplicate':
                                      controller
                                          .duplicateCandidate(candidate.id);
                                    case 'delete':
                                      controller.removeCandidate(candidate.id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'duplicate',
                                    child: Text('Duplicate'),
                                  ),
                                  if (!locked)
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                ],
                              ),
                              ReorderableDragStartListener(
                                index: i,
                                child: const Icon(Icons.drag_handle),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showEditor(
    BuildContext context,
    CreateWizardController controller, {
    Candidate? existing,
  }) {
    showAppSheet<void>(
      context,
      child: _CandidateEditor(controller: controller, existing: existing),
    );
  }
}

class _CandidateEditor extends StatefulWidget {
  const _CandidateEditor({required this.controller, this.existing});

  final CreateWizardController controller;
  final Candidate? existing;

  @override
  State<_CandidateEditor> createState() => _CandidateEditorState();
}

class _CandidateEditorState extends State<_CandidateEditor> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _subtitle =
      TextEditingController(text: widget.existing?.subtitle ?? '');
  late final _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final _notes =
      TextEditingController(text: widget.existing?.organizerNotes ?? '');

  @override
  void dispose() {
    _name.dispose();
    _subtitle.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    if (widget.existing != null) {
      widget.controller.updateCandidate(widget.existing!.copyWith(
        name: _name.text.trim(),
        subtitle: _subtitle.text.trim(),
        description: _description.text.trim(),
        organizerNotes: _notes.text.trim(),
      ));
    } else {
      widget.controller.addCandidate(
        name: _name.text.trim(),
        subtitle: _subtitle.text.trim(),
        description: _description.text.trim(),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? 'Add option' : 'Edit option',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: Spacing.lg),
          TextField(
            controller: _name,
            autofocus: widget.existing == null,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name or title'),
          ),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _subtitle,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Short subtitle (optional)',
            ),
          ),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _description,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Private notes (optional)',
              helperText:
                  'Only you can see these — never shown to participants',
            ),
          ),
          const SizedBox(height: Spacing.xl),
          FilledButton(
            onPressed: _save,
            child:
                Text(widget.existing == null ? 'Add option' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}

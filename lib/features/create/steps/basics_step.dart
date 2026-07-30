import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/widgets/candidate_avatar.dart';
import '../../../domain/models/enums.dart';
import '../create_wizard_controller.dart';

const _coverEmojis = [
  '🗳️',
  '🌟',
  '🏆',
  '🎨',
  '🎓',
  '🚴',
  '📚',
  '🎉',
  '💡',
  '🏕️'
];

/// Step 1: title, descriptions, category, cover, location, language.
class BasicsStep extends StatefulWidget {
  const BasicsStep({super.key, required this.state, required this.controller});

  final WizardState state;
  final CreateWizardController controller;

  @override
  State<BasicsStep> createState() => _BasicsStepState();
}

class _BasicsStepState extends State<BasicsStep> {
  late final _title = TextEditingController(text: widget.state.draft.title);
  late final _short =
      TextEditingController(text: widget.state.draft.shortDescription);
  late final _long =
      TextEditingController(text: widget.state.draft.longDescription);
  late final _location =
      TextEditingController(text: widget.state.draft.location);
  late final _organizerName =
      TextEditingController(text: widget.state.draft.organizerName);

  @override
  void dispose() {
    _title.dispose();
    _short.dispose();
    _long.dispose();
    _location.dispose();
    _organizerName.dispose();
    super.dispose();
  }

  void _commit() {
    widget.controller.updateDraft(widget.state.draft.copyWith(
      title: _title.text,
      shortDescription: _short.text,
      longDescription: _long.text,
      location: _location.text,
      organizerName: _organizerName.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.state.draft;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 80,
          onChanged: (_) => _commit(),
          decoration: const InputDecoration(
            labelText: 'Event title',
            hintText: 'e.g. Community Star Award 2026',
          ),
        ),
        const SizedBox(height: Spacing.md),
        TextField(
          controller: _short,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 140,
          onChanged: (_) => _commit(),
          decoration: const InputDecoration(
            labelText: 'Short description',
            hintText: 'One sentence participants see first',
          ),
        ),
        const SizedBox(height: Spacing.md),
        TextField(
          controller: _long,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 4,
          onChanged: (_) => _commit(),
          decoration: const InputDecoration(
            labelText: 'Detailed description (optional)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Text('Category', style: theme.textTheme.titleSmall),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          children: [
            for (final category in EventCategory.values)
              ChoiceChip(
                label: Text(category.label),
                selected: draft.category == category,
                onSelected: (_) => widget.controller
                    .updateDraft(draft.copyWith(category: category)),
              ),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        Text('Cover artwork', style: theme.textTheme.titleSmall),
        const SizedBox(height: Spacing.sm),
        EventCoverArt(
          coverSeed: draft.coverSeed,
          emoji: draft.coverEmoji,
          height: 120,
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _coverEmojis.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: Spacing.sm),
                  itemBuilder: (context, i) {
                    final emoji = _coverEmojis[i];
                    final selected = draft.coverEmoji == emoji;
                    return InkWell(
                      borderRadius: BorderRadius.circular(Corners.md),
                      onTap: () => widget.controller
                          .updateDraft(draft.copyWith(coverEmoji: emoji)),
                      child: Container(
                        width: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Corners.md),
                          border: Border.all(
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            IconButton.outlined(
              tooltip: 'Shuffle gradient',
              onPressed: () => widget.controller.updateDraft(
                draft.copyWith(coverSeed: draft.coverSeed + 1),
              ),
              icon: const Icon(Icons.shuffle),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        TextField(
          controller: _location,
          onChanged: (_) => _commit(),
          decoration: const InputDecoration(
            labelText: 'Location (optional)',
            prefixIcon: Icon(Icons.place_outlined),
          ),
        ),
        const SizedBox(height: Spacing.md),
        TextField(
          controller: _organizerName,
          onChanged: (_) => _commit(),
          decoration: const InputDecoration(
            labelText: 'Organizer display name',
            helperText: 'Shown to participants on the event page',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: Spacing.md),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: draft.language,
          decoration: const InputDecoration(
            labelText: 'Event language',
            prefixIcon: Icon(Icons.language),
          ),
          items: const [
            DropdownMenuItem(value: 'English', child: Text('English')),
            DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
            DropdownMenuItem(value: 'French', child: Text('French')),
            DropdownMenuItem(value: 'German', child: Text('German')),
            DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
          ],
          onChanged: (v) {
            if (v != null) {
              widget.controller.updateDraft(draft.copyWith(language: v));
            }
          },
        ),
      ],
    );
  }
}

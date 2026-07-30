import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/common.dart';
import '../auth/session_controller.dart';
import 'create_wizard_controller.dart';
import 'steps/access_step.dart';
import 'steps/basics_step.dart';
import 'steps/candidates_step.dart';
import 'steps/preview_step.dart';
import 'steps/rules_step.dart';
import 'steps/schedule_step.dart';

const _stepTitles = {
  WizardStep.basics: 'Event basics',
  WizardStep.candidates: 'Options',
  WizardStep.rules: 'Voting rules',
  WizardStep.access: 'Access & verification',
  WizardStep.schedule: 'Schedule & results',
  WizardStep.preview: 'Preview & publish',
};

/// Six-step creation wizard with save-and-exit at every step.
class CreateWizardScreen extends ConsumerWidget {
  const CreateWizardScreen({super.key, this.eventId});

  final String? eventId;

  String get _arg => eventId ?? '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (!session.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create event')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: Spacing.lg),
                Text(
                  'Sign in to create events',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: Spacing.sm),
                const Text(
                  'Organizers need a verified account so participants can trust who runs an event.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xl),
                FilledButton(
                  onPressed: () => context.push('/auth/register'),
                  child: const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final state = ref.watch(createWizardProvider(_arg));
    final controller = ref.read(createWizardProvider(_arg).notifier);
    final stepIndex = WizardStep.values.indexOf(state.step);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _saveAndExit(context, controller);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_stepTitles[state.step]!),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Save and exit',
            onPressed: () => _saveAndExit(context, controller),
          ),
          actions: [
            TextButton(
              onPressed: state.status == WizardStatus.saving
                  ? null
                  : () async {
                      final saved = await controller.saveDraft();
                      if (saved && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Draft saved')),
                        );
                      }
                    },
              child: const Text('Save'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: (stepIndex + 1) / WizardStep.values.length,
              ),
              duration: Motion.of(context, Motion.standard),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (state.message != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.md,
                    Spacing.lg,
                    0,
                  ),
                  child: InfoCallout(
                    text: state.message!,
                    icon: Icons.error_outline,
                    tone: CalloutTone.danger,
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.of(context, Motion.standard),
                  child: KeyedSubtree(
                    key: ValueKey(state.step),
                    child: switch (state.step) {
                      WizardStep.basics =>
                        BasicsStep(state: state, controller: controller),
                      WizardStep.candidates =>
                        CandidatesStep(state: state, controller: controller),
                      WizardStep.rules =>
                        RulesStep(state: state, controller: controller),
                      WizardStep.access =>
                        AccessStep(state: state, controller: controller),
                      WizardStep.schedule =>
                        ScheduleStep(state: state, controller: controller),
                      WizardStep.preview =>
                        PreviewStep(state: state, controller: controller),
                    },
                  ),
                ),
              ),
              _WizardNav(state: state, controller: controller),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndExit(
    BuildContext context,
    CreateWizardController controller,
  ) async {
    await controller.saveDraft();
    if (context.mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }
}

class _WizardNav extends StatelessWidget {
  const _WizardNav({required this.state, required this.controller});

  final WizardState state;
  final CreateWizardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFirst = state.step == WizardStep.basics;
    final isPreview = state.step == WizardStep.preview;
    final canAdvance = switch (state.step) {
      WizardStep.basics => state.basicsComplete,
      WizardStep.candidates => state.candidatesComplete,
      WizardStep.rules => state.rulesComplete,
      _ => true,
    };

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border:
            Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              child: OutlinedButton(
                onPressed: controller.back,
                child: const Text('Back'),
              ),
            ),
          if (!isFirst) const SizedBox(width: Spacing.md),
          Expanded(
            flex: 2,
            child: isPreview
                ? const SizedBox.shrink() // publish button lives in PreviewStep
                : FilledButton(
                    onPressed: canAdvance
                        ? () {
                            Haptics.selection();
                            controller.next();
                          }
                        : null,
                    child: const Text('Continue'),
                  ),
          ),
        ],
      ),
    );
  }
}

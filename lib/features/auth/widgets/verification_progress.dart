import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

const _steps = ['Account', 'Email', 'Phone'];

/// Three-step progress indicator for organizer verification.
class VerificationProgress extends StatelessWidget {
  const VerificationProgress({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label:
          'Step ${currentStep + 1} of ${_steps.length}: ${_steps[currentStep]}',
      child: Row(
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                  color:
                      i <= currentStep ? scheme.primary : scheme.outlineVariant,
                ),
              ),
            Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < currentStep
                        ? scheme.primary
                        : i == currentStep
                            ? scheme.primary.withValues(alpha: 0.15)
                            : scheme.surfaceContainerLow,
                    border: Border.all(
                      color: i <= currentStep
                          ? scheme.primary
                          : scheme.outlineVariant,
                    ),
                  ),
                  child: i < currentStep
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Center(
                          child: Text(
                            '${i + 1}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: i == currentStep
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(_steps[i], style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

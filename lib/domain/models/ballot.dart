import 'package:flutter/foundation.dart';

import 'enums.dart';
import 'event.dart';

/// A participant's in-progress ballot. Selection order matters for ranked
/// choice (index 0 = rank 1).
@immutable
class BallotDraft {
  const BallotDraft({
    required this.eventId,
    required this.ballotType,
    this.selections = const [],
    this.clientToken,
  });

  final String eventId;
  final BallotType ballotType;
  final List<String> selections;

  /// Idempotency token generated once per ballot attempt so retries after a
  /// network interruption never produce a second ballot.
  final String? clientToken;

  BallotDraft copyWith({List<String>? selections, String? clientToken}) {
    return BallotDraft(
      eventId: eventId,
      ballotType: ballotType,
      selections: selections ?? this.selections,
      clientToken: clientToken ?? this.clientToken,
    );
  }

  BallotValidation validate(VotingRules rules, int candidateCount) {
    switch (ballotType) {
      case BallotType.singleChoice:
        if (selections.length != 1) {
          return const BallotValidation(
              false, 'Select one option to continue.');
        }
        return const BallotValidation(true, '');
      case BallotType.multipleChoice:
        if (selections.length < rules.minSelections) {
          final needed = rules.minSelections - selections.length;
          return BallotValidation(
            false,
            'Select at least ${rules.minSelections} '
            '(${needed} more to go).',
          );
        }
        if (selections.length > rules.maxSelections) {
          return BallotValidation(
            false,
            'You can select up to ${rules.maxSelections}.',
          );
        }
        return const BallotValidation(true, '');
      case BallotType.rankedChoice:
        if (selections.toSet().length != selections.length) {
          return const BallotValidation(
              false, 'Each option can only hold one rank.');
        }
        if (rules.requireFullRanking && selections.length < candidateCount) {
          return BallotValidation(
            false,
            'Rank all $candidateCount options to continue.',
          );
        }
        if (selections.isEmpty) {
          return const BallotValidation(false, 'Rank at least one option.');
        }
        return const BallotValidation(true, '');
      case BallotType.score:
        return const BallotValidation(
            false, 'Score voting is not available yet.');
    }
  }
}

@immutable
class BallotValidation {
  const BallotValidation(this.isValid, this.message);
  final bool isValid;
  final String message;
}

/// Non-identifying acceptance receipt. Confirms acceptance only; it does not
/// reveal or encode the ballot's selections.
@immutable
class BallotReceipt {
  const BallotReceipt({
    required this.receiptCode,
    required this.eventId,
    required this.acceptedAt,
  });

  final String receiptCode;
  final String eventId;
  final DateTime acceptedAt;
}

/// Explicit outcomes for a submission attempt. UI must never infer acceptance
/// from a local success state.
sealed class BallotSubmissionResult {
  const BallotSubmissionResult();
}

class BallotAccepted extends BallotSubmissionResult {
  const BallotAccepted(this.receipt);
  final BallotReceipt receipt;
}

class BallotAlreadyCast extends BallotSubmissionResult {
  const BallotAlreadyCast(this.existingReceipt);
  final BallotReceipt? existingReceipt;
}

class BallotEventClosed extends BallotSubmissionResult {
  const BallotEventClosed();
}

class BallotVerificationExpired extends BallotSubmissionResult {
  const BallotVerificationExpired();
}

class BallotInvalid extends BallotSubmissionResult {
  const BallotInvalid(this.reason);
  final String reason;
}

/// Transport failed before the server confirmed anything. The outcome is
/// unknown — the caller must retry with the same client token.
class BallotOutcomeUnknown extends BallotSubmissionResult {
  const BallotOutcomeUnknown();
}

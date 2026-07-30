import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/providers.dart';
import '../../domain/models/ballot.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/event.dart';

/// Every major ballot-flow state, modeled explicitly (no boolean explosion).
enum BallotPhase {
  loading,
  loadError,
  eventNotFound,
  needsVerification,
  verifying,
  building,
  submitting,

  /// Transport failed mid-submit; the outcome is unknown. We keep the same
  /// idempotency token and re-confirm — never tell the user it failed.
  confirmingOutcome,
  accepted,
  alreadyVoted,
  eventClosed,
  verificationExpired,
  invalid,
}

@immutable
class BallotFlowState {
  const BallotFlowState({
    this.phase = BallotPhase.loading,
    this.event,
    this.draft,
    this.receipt,
    this.message,
  });

  final BallotPhase phase;
  final VotingEvent? event;
  final BallotDraft? draft;
  final BallotReceipt? receipt;
  final String? message;

  BallotValidation get validation {
    final e = event;
    final d = draft;
    if (e == null || d == null) {
      return const BallotValidation(false, 'Loading…');
    }
    return d.validate(e.rules, e.activeCandidates.length);
  }

  bool get hasUnsavedSelections =>
      (draft?.selections.isNotEmpty ?? false) &&
      phase != BallotPhase.accepted &&
      phase != BallotPhase.alreadyVoted;

  BallotFlowState copyWith({
    BallotPhase? phase,
    VotingEvent? event,
    BallotDraft? draft,
    BallotReceipt? receipt,
    String? message,
    bool clearMessage = false,
  }) {
    return BallotFlowState(
      phase: phase ?? this.phase,
      event: event ?? this.event,
      draft: draft ?? this.draft,
      receipt: receipt ?? this.receipt,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class BallotFlowController extends FamilyNotifier<BallotFlowState, String> {
  @override
  BallotFlowState build(String publicId) {
    Future.microtask(load);
    return const BallotFlowState();
  }

  String get _publicId => arg;

  Future<void> load() async {
    state = const BallotFlowState(phase: BallotPhase.loading);
    try {
      final event =
          await ref.read(eventRepositoryProvider).getByPublicId(_publicId);
      if (event == null) {
        state = const BallotFlowState(phase: BallotPhase.eventNotFound);
        return;
      }
      final receipt =
          await ref.read(ballotRepositoryProvider).existingReceipt(event.id);
      if (receipt != null) {
        state = BallotFlowState(
          phase: BallotPhase.alreadyVoted,
          event: event,
          receipt: receipt,
        );
        return;
      }
      if (event.isClosed ||
          (event.endsAt != null && event.endsAt!.isBefore(DateTime.now()))) {
        state = BallotFlowState(phase: BallotPhase.eventClosed, event: event);
        return;
      }
      final draft = BallotDraft(
        eventId: event.id,
        ballotType: event.rules.ballotType,
      );
      final needsVerification =
          event.verificationLevel == VerificationLevel.phone;
      state = BallotFlowState(
        phase: needsVerification
            ? BallotPhase.needsVerification
            : BallotPhase.building,
        event: event,
        draft: draft,
      );
    } catch (_) {
      state = const BallotFlowState(
        phase: BallotPhase.loadError,
        message: 'We could not load this event. Check your connection.',
      );
    }
  }

  /// Mock participant phone verification for phone-verified events.
  Future<bool> completeVerification(String otp) async {
    state = state.copyWith(phase: BallotPhase.verifying, clearMessage: true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final valid = RegExp(r'^\d{6}$').hasMatch(otp) && int.parse(otp[5]).isEven;
    if (valid) {
      state = state.copyWith(phase: BallotPhase.building);
      return true;
    }
    state = state.copyWith(
      phase: BallotPhase.needsVerification,
      message: 'That code did not match. Try again.',
    );
    return false;
  }

  void toggleSelection(String candidateId) {
    final draft = state.draft;
    final event = state.event;
    if (draft == null || event == null || state.phase != BallotPhase.building) {
      return;
    }
    final selections = List<String>.of(draft.selections);
    switch (draft.ballotType) {
      case BallotType.singleChoice:
        selections
          ..clear()
          ..add(candidateId);
      case BallotType.multipleChoice:
        if (selections.contains(candidateId)) {
          selections.remove(candidateId);
        } else if (selections.length < event.rules.maxSelections) {
          selections.add(candidateId);
        } else {
          state = state.copyWith(
            message:
                'You can select up to ${event.rules.maxSelections}. Remove one first.',
          );
          return;
        }
      case BallotType.rankedChoice:
        if (selections.contains(candidateId)) {
          selections.remove(candidateId);
        } else {
          selections.add(candidateId); // appended at next rank
        }
      case BallotType.score:
        return;
    }
    state = state.copyWith(
      draft: draft.copyWith(selections: selections),
      clearMessage: true,
    );
  }

  void reorderRanking(int oldIndex, int newIndex) {
    final draft = state.draft;
    if (draft == null) return;
    final selections = List<String>.of(draft.selections);
    if (oldIndex < 0 || oldIndex >= selections.length) return;
    var target = newIndex;
    if (target > oldIndex) target--;
    final item = selections.removeAt(oldIndex);
    selections.insert(target.clamp(0, selections.length), item);
    state = state.copyWith(draft: draft.copyWith(selections: selections));
  }

  void resetRanking() {
    final draft = state.draft;
    if (draft == null) return;
    state = state.copyWith(draft: draft.copyWith(selections: []));
  }

  Future<void> submit() async {
    final draft = state.draft;
    final event = state.event;
    if (draft == null || event == null) return;
    if (!state.validation.isValid) return;

    // Idempotency token survives retries and app restarts within this flow.
    final tokened = draft.clientToken != null
        ? draft
        : draft.copyWith(
            clientToken: const Uuid().v4(),
          );
    state = state.copyWith(phase: BallotPhase.submitting, draft: tokened);

    final result = await ref.read(ballotRepositoryProvider).submit(tokened);
    _applyResult(result);
  }

  /// Retry after an unknown outcome — same token, so it is safe.
  Future<void> confirmOutcome() async {
    final draft = state.draft;
    if (draft?.clientToken == null) return;
    state = state.copyWith(phase: BallotPhase.confirmingOutcome);
    final result = await ref.read(ballotRepositoryProvider).submit(draft!);
    _applyResult(result);
  }

  void _applyResult(BallotSubmissionResult result) {
    switch (result) {
      case BallotAccepted(:final receipt):
        state = state.copyWith(phase: BallotPhase.accepted, receipt: receipt);
      case BallotAlreadyCast(:final existingReceipt):
        state = state.copyWith(
          phase: BallotPhase.alreadyVoted,
          receipt: existingReceipt,
        );
      case BallotEventClosed():
        state = state.copyWith(phase: BallotPhase.eventClosed);
      case BallotVerificationExpired():
        state = state.copyWith(
          phase: BallotPhase.verificationExpired,
          message:
              'Your verification session expired. Verify again to continue — '
              'your selections are saved.',
        );
      case BallotInvalid(:final reason):
        state = state.copyWith(phase: BallotPhase.invalid, message: reason);
      case BallotOutcomeUnknown():
        state = state.copyWith(
          phase: BallotPhase.confirmingOutcome,
          message: 'We are confirming whether your ballot was accepted.',
        );
    }
  }
}

final ballotFlowProvider =
    NotifierProvider.family<BallotFlowController, BallotFlowState, String>(
  BallotFlowController.new,
);

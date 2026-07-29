import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/models/candidate.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/event.dart';
import '../auth/session_controller.dart';

enum WizardStep { basics, candidates, rules, access, schedule, preview }

enum WizardStatus { editing, saving, publishing, published, error }

@immutable
class WizardState {
  const WizardState({
    required this.draft,
    this.step = WizardStep.basics,
    this.status = WizardStatus.editing,
    this.message,
  });

  final VotingEvent draft;
  final WizardStep step;
  final WizardStatus status;
  final String? message;

  /// Settings become immutable once an event has opened.
  bool get settingsLocked => !draft.isDraft;

  bool get basicsComplete => draft.title.trim().length >= 4;
  bool get candidatesComplete => draft.activeCandidates.length >= 2;
  bool get rulesComplete {
    final r = draft.rules;
    if (r.ballotType == BallotType.multipleChoice) {
      return r.minSelections >= 1 &&
          r.maxSelections >= r.minSelections &&
          r.maxSelections <= draft.activeCandidates.length;
    }
    return true;
  }

  bool get readyToPublish =>
      basicsComplete && candidatesComplete && rulesComplete;

  /// Effectively-indefinite events get a gentle warning before publish.
  bool get isIndefinite => draft.endsAt == null;

  WizardState copyWith({
    VotingEvent? draft,
    WizardStep? step,
    WizardStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return WizardState(
      draft: draft ?? this.draft,
      step: step ?? this.step,
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

/// Event-creation wizard. Family arg = existing draft id ('' for new events).
class CreateWizardController extends FamilyNotifier<WizardState, String> {
  @override
  WizardState build(String eventId) {
    if (eventId.isNotEmpty) {
      final existing =
          ref.read(mockBackendProvider).events[eventId];
      if (existing != null) return WizardState(draft: existing);
    }
    return WizardState(draft: _newDraft());
  }

  VotingEvent _newDraft() {
    final organizer = ref.read(sessionControllerProvider).organizer;
    final now = DateTime.now();
    final id = 'ev_${now.millisecondsSinceEpoch}';
    return VotingEvent(
      id: id,
      publicId: 'e${now.millisecondsSinceEpoch.toRadixString(36)}',
      title: '',
      organizerName: organizer?.fullName ?? 'You',
      visibility: EventVisibility.unlisted,
      rules: const VotingRules(ballotType: BallotType.singleChoice),
      verificationLevel: VerificationLevel.basicInstall,
      resultVisibility: ResultVisibility.afterClose,
      status: EventStatus.draft,
      candidates: const [],
      endsAt: now.add(const Duration(days: 7)), // sensible default deadline
      createdAt: now,
    );
  }

  void goTo(WizardStep step) =>
      state = state.copyWith(step: step, clearMessage: true);

  void next() {
    final index = WizardStep.values.indexOf(state.step);
    if (index < WizardStep.values.length - 1) {
      goTo(WizardStep.values[index + 1]);
    }
  }

  void back() {
    final index = WizardStep.values.indexOf(state.step);
    if (index > 0) goTo(WizardStep.values[index - 1]);
  }

  void updateDraft(VotingEvent draft) =>
      state = state.copyWith(draft: draft, clearMessage: true);

  // -- Candidates -----------------------------------------------------------

  void addCandidate({required String name, String subtitle = '', String description = ''}) {
    final candidates = List<Candidate>.of(state.draft.candidates);
    candidates.add(Candidate(
      id: 'c_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      subtitle: subtitle,
      description: description,
      colorSeed: candidates.length,
      order: candidates.length,
    ));
    updateDraft(state.draft.copyWith(candidates: candidates));
  }

  void updateCandidate(Candidate updated) {
    final candidates = [
      for (final c in state.draft.candidates)
        if (c.id == updated.id) updated else c,
    ];
    updateDraft(state.draft.copyWith(candidates: candidates));
  }

  void removeCandidate(String id) {
    if (state.settingsLocked) return; // no deletion after voting starts
    final candidates =
        state.draft.candidates.where((c) => c.id != id).toList();
    updateDraft(state.draft.copyWith(candidates: _reindex(candidates)));
  }

  void duplicateCandidate(String id) {
    final source = state.draft.candidates.firstWhere((c) => c.id == id);
    addCandidate(
      name: '${source.name} (copy)',
      subtitle: source.subtitle,
      description: source.description,
    );
  }

  void reorderCandidates(int oldIndex, int newIndex) {
    final candidates = List<Candidate>.of(state.draft.activeCandidates);
    var target = newIndex;
    if (target > oldIndex) target--;
    final item = candidates.removeAt(oldIndex);
    candidates.insert(target.clamp(0, candidates.length), item);
    updateDraft(state.draft.copyWith(candidates: _reindex(candidates)));
  }

  List<Candidate> _reindex(List<Candidate> candidates) => [
        for (var i = 0; i < candidates.length; i++)
          candidates[i].copyWith(order: i),
      ];

  // -- Persistence ----------------------------------------------------------

  Future<bool> saveDraft() async {
    state = state.copyWith(status: WizardStatus.saving);
    try {
      await ref.read(eventRepositoryProvider).saveDraft(state.draft);
      state = state.copyWith(status: WizardStatus.editing);
      return true;
    } catch (e) {
      state = state.copyWith(status: WizardStatus.error, message: '$e');
      return false;
    }
  }

  Future<bool> publish() async {
    if (!state.readyToPublish) return false;
    state = state.copyWith(status: WizardStatus.publishing);
    try {
      await ref.read(eventRepositoryProvider).saveDraft(state.draft);
      final published =
          await ref.read(eventRepositoryProvider).publish(state.draft.id);
      state = state.copyWith(draft: published, status: WizardStatus.published);
      return true;
    } catch (e) {
      state = state.copyWith(status: WizardStatus.error, message: '$e');
      return false;
    }
  }
}

final createWizardProvider =
    NotifierProvider.family<CreateWizardController, WizardState, String>(
  CreateWizardController.new,
);

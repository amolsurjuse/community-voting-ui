import 'package:flutter/foundation.dart';

@immutable
class CandidateTally {
  const CandidateTally({
    required this.candidateId,
    required this.votes,
  });

  final String candidateId;
  final int votes;
}

@immutable
class RankedRound {
  const RankedRound({
    required this.round,
    required this.tallies,
    this.eliminatedCandidateId,
    this.transferredVotes = 0,
    this.winnerCandidateId,
    this.note = '',
  });

  final int round;
  final List<CandidateTally> tallies;
  final String? eliminatedCandidateId;
  final int transferredVotes;
  final String? winnerCandidateId;
  final String note;
}

@immutable
class ResultsSnapshot {
  const ResultsSnapshot({
    required this.eventId,
    required this.totalBallots,
    required this.tallies,
    required this.updatedAt,
    this.rankedRounds = const [],
    this.isFinal = false,
    this.belowThreshold = false,
  });

  final String eventId;
  final int totalBallots;

  /// First-preference tallies for ranked events; direct tallies otherwise.
  final List<CandidateTally> tallies;
  final List<RankedRound> rankedRounds;
  final DateTime updatedAt;
  final bool isFinal;

  /// True when counts are hidden until a minimum participation threshold.
  final bool belowThreshold;

  List<CandidateTally> get sorted =>
      List.of(tallies)..sort((a, b) => b.votes.compareTo(a.votes));

  double fraction(String candidateId) {
    if (totalBallots == 0) return 0;
    final tally = tallies.where((t) => t.candidateId == candidateId);
    if (tally.isEmpty) return 0;
    return tally.first.votes / totalBallots;
  }

  /// Leading candidate ids (more than one means a tie for first place).
  List<String> get leaders {
    if (tallies.isEmpty || totalBallots == 0) return const [];
    final top = sorted.first.votes;
    if (top == 0) return const [];
    return sorted.where((t) => t.votes == top).map((t) => t.candidateId).toList();
  }

  bool get isTie => leaders.length > 1;
}

import 'dart:math';

import '../domain/models/candidate.dart';
import '../domain/models/results.dart';

/// Instant-runoff round computation over synthetic full ballots derived from
/// first-preference tallies. In production, rounds come from the server; this
/// mirrors the shape of that contract.
class RankedChoiceCounter {
  RankedChoiceCounter._();

  static List<RankedRound> computeRounds({
    required List<Candidate> candidates,
    required Map<String, int> firstPreferences,
    required int seed,
  }) {
    if (candidates.length < 2) return const [];
    final random = Random(seed);
    final ids = candidates.map((c) => c.id).toList();

    // Build synthetic ballots: each first-preference block gets a plausible
    // ranking of the remaining candidates.
    final ballots = <List<String>>[];
    for (final id in ids) {
      final count = firstPreferences[id] ?? 0;
      for (var i = 0; i < count; i++) {
        final rest = List.of(ids)..remove(id);
        rest.shuffle(random);
        ballots.add([id, ...rest]);
      }
    }
    if (ballots.isEmpty) return const [];

    final rounds = <RankedRound>[];
    final eliminated = <String>{};
    var round = 1;

    while (true) {
      final counts = {for (final id in ids) id: 0};
      for (final ballot in ballots) {
        final pick = ballot.where((id) => !eliminated.contains(id));
        if (pick.isNotEmpty) counts[pick.first] = counts[pick.first]! + 1;
      }
      final active = ids.where((id) => !eliminated.contains(id)).toList();
      final total = active.fold<int>(0, (sum, id) => sum + counts[id]!);
      final majority = total ~/ 2 + 1;
      final tallies = [
        for (final id in active)
          CandidateTally(candidateId: id, votes: counts[id]!),
      ]..sort((a, b) => b.votes.compareTo(a.votes));

      final leader = tallies.first;
      if (leader.votes >= majority || active.length <= 2) {
        rounds.add(RankedRound(
          round: round,
          tallies: tallies,
          winnerCandidateId: leader.candidateId,
          note: leader.votes >= majority
              ? 'Reached the majority threshold of $majority ballots.'
              : 'Won the final head-to-head round.',
        ));
        break;
      }

      // Eliminate the lowest; break exact ties by earlier round support order.
      final lowest = tallies.last;
      final transferred = lowest.votes;
      eliminated.add(lowest.candidateId);
      rounds.add(RankedRound(
        round: round,
        tallies: tallies,
        eliminatedCandidateId: lowest.candidateId,
        transferredVotes: transferred,
        note:
            'Lowest candidate eliminated; $transferred ballots moved to their next choice.',
      ));
      round++;
      if (round > ids.length + 1) break; // safety guard
    }
    return rounds;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pulsevote/data/mock_backend.dart';
import 'package:pulsevote/data/seed_data.dart';
import 'package:pulsevote/domain/models/ballot.dart';
import 'package:pulsevote/domain/models/enums.dart';

void main() {
  late MockBackend backend;

  setUp(() => backend = MockBackend());
  tearDown(() => backend.dispose());

  group('Ballot submission', () {
    test('accepts a valid ballot and issues a receipt', () {
      final event = SeedData.communityAward;
      final draft = BallotDraft(
        eventId: event.id,
        ballotType: BallotType.singleChoice,
        selections: [event.candidates.first.id],
        clientToken: 'tok-1',
      );
      final result = backend.recordBallot(draft);
      expect(result, isA<BallotAccepted>());
      final receipt = (result as BallotAccepted).receipt;
      expect(receipt.receiptCode, isNotEmpty);
      // Receipt must not encode the selection.
      expect(
        receipt.receiptCode.contains(event.candidates.first.id),
        isFalse,
      );
    });

    test('rejects a duplicate ballot from the same installation', () {
      final event = SeedData.communityAward;
      final first = BallotDraft(
        eventId: event.id,
        ballotType: BallotType.singleChoice,
        selections: [event.candidates.first.id],
        clientToken: 'tok-1',
      );
      backend.recordBallot(first);

      final second = BallotDraft(
        eventId: event.id,
        ballotType: BallotType.singleChoice,
        selections: [event.candidates.last.id],
        clientToken: 'tok-2',
      );
      final result = backend.recordBallot(second);
      expect(result, isA<BallotAlreadyCast>());
    });

    test('idempotent retry with same client token replays original outcome', () {
      final event = SeedData.communityAward;
      final draft = BallotDraft(
        eventId: event.id,
        ballotType: BallotType.singleChoice,
        selections: [event.candidates.first.id],
        clientToken: 'tok-same',
      );
      final first = backend.recordBallot(draft);
      final totalAfterFirst = backend.events[event.id]!.totalBallots;

      final retry = backend.recordBallot(draft);
      expect(retry, isA<BallotAccepted>());
      expect(
        (retry as BallotAccepted).receipt.receiptCode,
        (first as BallotAccepted).receipt.receiptCode,
      );
      // No double count.
      expect(backend.events[event.id]!.totalBallots, totalAfterFirst);
    });

    test('rejects ballots for closed or expired events', () {
      final closed = SeedData.closedEvent;
      final draft = BallotDraft(
        eventId: closed.id,
        ballotType: BallotType.singleChoice,
        selections: [closed.candidates.first.id],
        clientToken: 'tok-closed',
      );
      expect(backend.recordBallot(draft), isA<BallotEventClosed>());
    });

    test('rejects invalid ballots with a reason', () {
      final event = SeedData.employeePoll; // multiple choice, min 1 max 3
      final draft = BallotDraft(
        eventId: event.id,
        ballotType: BallotType.multipleChoice,
        selections: [
          for (final c in event.candidates) c.id, // too many
        ],
        clientToken: 'tok-invalid',
      );
      final result = backend.recordBallot(draft);
      expect(result, isA<BallotInvalid>());
      expect((result as BallotInvalid).reason, isNotEmpty);
    });
  });

  group('Results', () {
    test('snapshot totals match tallies for non-ranked events', () {
      final event = SeedData.communityAward;
      final snapshot = backend.snapshot(event.id);
      final sum = snapshot.tallies.fold<int>(0, (acc, t) => acc + t.votes);
      expect(sum, snapshot.totalBallots);
    });

    test('ranked event produces rounds ending with a winner', () {
      final snapshot = backend.snapshot(SeedData.rankedVote.id);
      expect(snapshot.rankedRounds, isNotEmpty);
      expect(snapshot.rankedRounds.last.winnerCandidateId, isNotNull);
      // Every non-final round eliminates exactly one candidate.
      for (final round
          in snapshot.rankedRounds.take(snapshot.rankedRounds.length - 1)) {
        expect(round.eliminatedCandidateId, isNotNull);
      }
    });

    test('live vote simulation only affects open events', () {
      final closedBefore =
          backend.events[SeedData.closedEvent.id]!.totalBallots;
      backend.simulateIncomingVote(SeedData.closedEvent.id);
      expect(
        backend.events[SeedData.closedEvent.id]!.totalBallots,
        closedBefore,
      );

      final openBefore =
          backend.events[SeedData.communityAward.id]!.totalBallots;
      backend.simulateIncomingVote(SeedData.communityAward.id);
      expect(
        backend.events[SeedData.communityAward.id]!.totalBallots,
        openBefore + 1,
      );
    });
  });

  group('Result visibility policy', () {
    test('organizer-only results are hidden from participants', () {
      final event = SeedData.communityAward
          .copyWith(resultVisibility: ResultVisibility.organizerOnly);
      expect(event.canSeeResults(hasVoted: true), isFalse);
      expect(event.canSeeResults(hasVoted: true, isOrganizer: true), isTrue);
    });

    test('after-vote results require a cast ballot while open', () {
      final event = SeedData.communityAward
          .copyWith(resultVisibility: ResultVisibility.afterVote);
      expect(event.canSeeResults(hasVoted: false), isFalse);
      expect(event.canSeeResults(hasVoted: true), isTrue);
    });

    test('after-close results open up once the event closes', () {
      final event = SeedData.closedEvent;
      expect(event.canSeeResults(hasVoted: false), isTrue);
    });
  });
}

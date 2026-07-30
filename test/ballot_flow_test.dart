import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsevote/data/providers.dart';
import 'package:pulsevote/data/seed_data.dart';
import 'package:pulsevote/features/ballot/ballot_controller.dart';

Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 1600));

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  group('Ballot flow', () {
    test('loads open event into building phase', () async {
      final provider = ballotFlowProvider(SeedData.communityAward.publicId);
      container.read(provider);
      await settle();
      expect(container.read(provider).phase, BallotPhase.building);
    });

    test('phone-verified event requires verification first', () async {
      final provider = ballotFlowProvider(SeedData.clubElection.publicId);
      container.read(provider);
      await settle();
      expect(container.read(provider).phase, BallotPhase.needsVerification);

      final ok = await container
          .read(provider.notifier)
          .completeVerification('111112');
      expect(ok, isTrue);
      expect(container.read(provider).phase, BallotPhase.building);
    });

    test('expired verification codes are rejected', () async {
      final provider = ballotFlowProvider(SeedData.clubElection.publicId);
      container.read(provider);
      await settle();
      final ok = await container
          .read(provider.notifier)
          .completeVerification('111111'); // odd final digit -> invalid
      expect(ok, isFalse);
      expect(
        container.read(provider).phase,
        BallotPhase.needsVerification,
      );
    });

    test('closed event resolves to eventClosed phase', () async {
      final provider = ballotFlowProvider(SeedData.closedEvent.publicId);
      container.read(provider);
      await settle();
      expect(container.read(provider).phase, BallotPhase.eventClosed);
    });

    test('unknown link resolves to eventNotFound', () async {
      final provider = ballotFlowProvider('no-such-event');
      container.read(provider);
      await settle();
      expect(container.read(provider).phase, BallotPhase.eventNotFound);
    });

    test('submit accepts a valid ballot and stores receipt', () async {
      final provider = ballotFlowProvider(SeedData.communityAward.publicId);
      container.read(provider);
      await settle();
      final notifier = container.read(provider.notifier);
      final candidateId =
          container.read(provider).event!.activeCandidates.first.id;
      notifier.toggleSelection(candidateId);
      await notifier.submit();
      final state = container.read(provider);
      expect(state.phase, BallotPhase.accepted);
      expect(state.receipt, isNotNull);
    });

    test('network interruption during submit is retry-safe (idempotent)',
        () async {
      final backend = container.read(mockBackendProvider);
      backend.simulateNetworkFlakeOnce = true;

      final provider = ballotFlowProvider(SeedData.rankedVote.publicId);
      container.read(provider);
      await settle();
      final notifier = container.read(provider.notifier);
      final candidates = container.read(provider).event!.activeCandidates;
      notifier.toggleSelection(candidates[0].id);
      notifier.toggleSelection(candidates[1].id);

      await notifier.submit();
      // Outcome unknown — never presented as failure.
      expect(container.read(provider).phase, BallotPhase.confirmingOutcome);

      await notifier.confirmOutcome();
      expect(container.read(provider).phase, BallotPhase.accepted);

      // A second confirm must not create a duplicate.
      final total = backend.events[SeedData.rankedVote.id]!.totalBallots;
      await notifier.confirmOutcome();
      expect(backend.events[SeedData.rankedVote.id]!.totalBallots, total);
    });

    test('ranked ordering: toggle appends, reorder moves, reset clears',
        () async {
      final provider = ballotFlowProvider(SeedData.rankedVote.publicId);
      container.read(provider);
      await settle();
      final notifier = container.read(provider.notifier);
      final ids = container
          .read(provider)
          .event!
          .activeCandidates
          .map((c) => c.id)
          .toList();

      notifier.toggleSelection(ids[0]);
      notifier.toggleSelection(ids[1]);
      notifier.toggleSelection(ids[2]);
      expect(
          container.read(provider).draft!.selections, [ids[0], ids[1], ids[2]]);

      notifier.reorderRanking(2, 0); // move third pick to rank 1
      expect(
          container.read(provider).draft!.selections, [ids[2], ids[0], ids[1]]);

      notifier.resetRanking();
      expect(container.read(provider).draft!.selections, isEmpty);
    });

    test('already-voted installation goes straight to alreadyVoted', () async {
      final provider = ballotFlowProvider(SeedData.communityAward.publicId);
      container.read(provider);
      await settle();
      final notifier = container.read(provider.notifier);
      notifier.toggleSelection(
        container.read(provider).event!.activeCandidates.first.id,
      );
      await notifier.submit();
      expect(container.read(provider).phase, BallotPhase.accepted);

      // Reload the flow, as if reopening from a deep link.
      await notifier.load();
      expect(container.read(provider).phase, BallotPhase.alreadyVoted);
      expect(container.read(provider).receipt, isNotNull);
    });
  });
}

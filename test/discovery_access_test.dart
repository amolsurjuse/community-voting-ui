import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsevote/data/providers.dart';
import 'package:pulsevote/data/seed_data.dart';
import 'package:pulsevote/domain/models/enums.dart';
import 'package:pulsevote/domain/repositories.dart';

void main() {
  late ProviderContainer container;
  late EventRepository repo;

  setUp(() {
    container = ProviderContainer();
    repo = container.read(eventRepositoryProvider);
  });
  tearDown(() => container.dispose());

  group('Public discovery', () {
    test('only public, non-draft events are discoverable', () async {
      final results = await repo.discover(const DiscoverFilters());
      expect(results, isNotEmpty);
      for (final event in results) {
        expect(event.visibility, EventVisibility.public);
        expect(event.isDraft, isFalse);
      }
      // The unlisted employee poll must never appear.
      expect(results.any((e) => e.id == SeedData.employeePoll.id), isFalse);
    });

    test('query and ballot-type filters narrow results', () async {
      final byQuery =
          await repo.discover(const DiscoverFilters(query: 'mural'));
      expect(byQuery.map((e) => e.id), [SeedData.rankedVote.id]);

      final ranked = await repo.discover(
        const DiscoverFilters(ballotType: BallotType.rankedChoice),
      );
      expect(ranked.every(
        (e) => e.rules.ballotType == BallotType.rankedChoice,
      ), isTrue);
    });

    test('pagination past the end returns an empty page', () async {
      expect(await repo.discover(const DiscoverFilters(), page: 99), isEmpty);
    });
  });

  group('Private/unlisted access', () {
    test('unlisted events resolve by direct link', () async {
      final event = await repo.getByPublicId(SeedData.employeePoll.publicId);
      expect(event, isNotNull);
    });

    test('invalid invitation token fails without exposing anything', () async {
      expect(await repo.redeemInvitation('not-a-real-token'), isNull);
    });

    test('valid invitation token resolves to its event', () async {
      final event = await repo.redeemInvitation('demo-invite-2026');
      expect(event, isNotNull);
      expect(event!.publicId, SeedData.employeePoll.publicId);
    });

    test('unknown public id resolves to null (private-event access failure)',
        () async {
      expect(await repo.getByPublicId('secret-private-event'), isNull);
    });
  });
}

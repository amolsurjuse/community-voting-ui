import 'package:flutter_test/flutter_test.dart';
import 'package:pulsevote/domain/models/ballot.dart';
import 'package:pulsevote/domain/models/enums.dart';
import 'package:pulsevote/domain/models/event.dart';

void main() {
  group('Single-choice validation', () {
    const rules = VotingRules(ballotType: BallotType.singleChoice);

    test('rejects empty ballot', () {
      const draft = BallotDraft(
        eventId: 'e1',
        ballotType: BallotType.singleChoice,
      );
      expect(draft.validate(rules, 5).isValid, isFalse);
    });

    test('accepts exactly one selection', () {
      const draft = BallotDraft(
        eventId: 'e1',
        ballotType: BallotType.singleChoice,
        selections: ['a'],
      );
      expect(draft.validate(rules, 5).isValid, isTrue);
    });
  });

  group('Multiple-choice min/max validation', () {
    const rules = VotingRules(
      ballotType: BallotType.multipleChoice,
      minSelections: 2,
      maxSelections: 3,
    );

    test('rejects below minimum', () {
      const draft = BallotDraft(
        eventId: 'e1',
        ballotType: BallotType.multipleChoice,
        selections: ['a'],
      );
      final result = draft.validate(rules, 6);
      expect(result.isValid, isFalse);
      expect(result.message, contains('at least 2'));
    });

    test('accepts within range', () {
      const draft = BallotDraft(
        eventId: 'e1',
        ballotType: BallotType.multipleChoice,
        selections: ['a', 'b'],
      );
      expect(draft.validate(rules, 6).isValid, isTrue);
    });

    test('rejects above maximum', () {
      const draft = BallotDraft(
        eventId: 'e1',
        ballotType: BallotType.multipleChoice,
        selections: ['a', 'b', 'c', 'd'],
      );
      expect(draft.validate(rules, 6).isValid, isFalse);
    });
  });

  group('Ranked-choice validation', () {
    test('rejects duplicate ranks', () {
      const rules = VotingRules(ballotType: BallotType.rankedChoice);
      const draft = BallotDraft(
        eventId: 'e1',
        ballotType: BallotType.rankedChoice,
        selections: ['a', 'b', 'a'],
      );
      expect(draft.validate(rules, 4).isValid, isFalse);
    });

    test('requires full ranking when configured', () {
      const rules = VotingRules(
        ballotType: BallotType.rankedChoice,
        requireFullRanking: true,
      );
      const partial = BallotDraft(
        eventId: 'e1',
        ballotType: BallotType.rankedChoice,
        selections: ['a', 'b'],
      );
      expect(partial.validate(rules, 4).isValid, isFalse);

      const full = BallotDraft(
        eventId: 'e1',
        ballotType: BallotType.rankedChoice,
        selections: ['a', 'b', 'c', 'd'],
      );
      expect(full.validate(rules, 4).isValid, isTrue);
    });

    test('accepts partial ranking when allowed', () {
      const rules = VotingRules(ballotType: BallotType.rankedChoice);
      const draft = BallotDraft(
        eventId: 'e1',
        ballotType: BallotType.rankedChoice,
        selections: ['b'],
      );
      expect(draft.validate(rules, 4).isValid, isTrue);
    });
  });
}

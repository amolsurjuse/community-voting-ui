import '../domain/models/activity.dart';
import '../domain/models/candidate.dart';
import '../domain/models/enums.dart';
import '../domain/models/event.dart';

/// Realistic sample data covering every event archetype the UI must handle.
class SeedData {
  SeedData._();

  static final DateTime _now = DateTime.now();

  static List<Candidate> _candidates(List<(String, String, String)> rows) {
    return [
      for (var i = 0; i < rows.length; i++)
        Candidate(
          id: 'c_${rows[i].$1.hashCode.abs()}_$i',
          name: rows[i].$1,
          subtitle: rows[i].$2,
          description: rows[i].$3,
          colorSeed: i,
          order: i,
        ),
    ];
  }

  /// 1. Public single-choice community award — open, live results.
  static final communityAward = VotingEvent(
    id: 'ev_award',
    publicId: 'riverside-award',
    title: 'Riverside Community Star Award 2026',
    shortDescription:
        'Celebrate the neighbor who made Riverside shine this year.',
    longDescription:
        'Every year, Riverside residents nominate neighbors who went above and '
        'beyond — organizing cleanups, running the food pantry, coaching kids. '
        'Vote for the person who inspired you most. The winner is announced at '
        'the Summer Block Party on August 15.',
    category: EventCategory.awards,
    coverSeed: 0,
    coverEmoji: '🌟',
    location: 'Riverside, Portland',
    organizerName: 'Riverside Neighborhood Association',
    visibility: EventVisibility.public,
    rules: const VotingRules(ballotType: BallotType.singleChoice),
    verificationLevel: VerificationLevel.basicInstall,
    resultVisibility: ResultVisibility.live,
    status: EventStatus.open,
    startsAt: _now.subtract(const Duration(days: 3)),
    endsAt: _now.add(const Duration(days: 4, hours: 6)),
    totalBallots: 312,
    candidates: _candidates([
      (
        'Maya Okafor',
        'Food pantry coordinator',
        'Runs the Tuesday pantry that served 4,000 meals this year and started the weekend delivery program for seniors.'
      ),
      (
        'Sam Delgado',
        'Youth soccer coach',
        'Coached three age groups for free all season and organized the equipment drive for new families.'
      ),
      (
        'Priya Nair',
        'Park cleanup organizer',
        'Led 14 riverbank cleanups and got the city to install new recycling stations along the trail.'
      ),
      (
        'Tom Whitfield',
        'Repair café founder',
        'Fixed over 200 household items at the monthly repair café, keeping them out of landfill.'
      ),
      (
        'Lena Kowalski',
        'Community garden lead',
        'Expanded the garden to 40 plots and donated surplus produce to the pantry every week.'
      ),
    ]),
    createdAt: _now.subtract(const Duration(days: 10)),
  );

  /// 2. Unlisted employee poll — multiple choice.
  static final employeePoll = VotingEvent(
    id: 'ev_offsite',
    publicId: 'aster-offsite',
    title: 'Aster Labs Offsite: Pick Our Activities',
    shortDescription:
        'Choose up to three activities for the September team offsite.',
    longDescription:
        'We have budget for three group activities at the Bend offsite '
        '(Sept 18–20). Pick the three you would actually join. Results guide '
        'the final agenda — the top three win.',
    category: EventCategory.workplace,
    coverSeed: 1,
    coverEmoji: '🏕️',
    organizerName: 'Aster Labs People Team',
    visibility: EventVisibility.unlisted,
    rules: const VotingRules(
      ballotType: BallotType.multipleChoice,
      minSelections: 1,
      maxSelections: 3,
    ),
    verificationLevel: VerificationLevel.verifiedInstall,
    resultVisibility: ResultVisibility.afterVote,
    status: EventStatus.open,
    startsAt: _now.subtract(const Duration(days: 1)),
    endsAt: _now.add(const Duration(days: 6)),
    totalBallots: 47,
    candidates: _candidates([
      (
        'River rafting',
        'Half day · Deschutes River',
        'Guided class II–III rafting with all gear provided. No experience needed.'
      ),
      (
        'Cooking class',
        'Evening · Downtown Bend',
        'Hands-on pasta workshop with a local chef, dinner included.'
      ),
      (
        'Trail hike + picnic',
        'Morning · Smith Rock',
        'Moderate 5-mile loop with a catered picnic at the viewpoint.'
      ),
      (
        'Escape rooms',
        'Evening · Teams of 6',
        'Three parallel rooms, mixed-team assignments to meet new people.'
      ),
      (
        'Volunteer afternoon',
        'Half day · Bend Food Project',
        'Sort and pack food boxes as a team for local families.'
      ),
      (
        'Board game night',
        'Evening · Lodge',
        'Casual games, snacks, and a bracket for the competitive.'
      ),
    ]),
    createdAt: _now.subtract(const Duration(days: 5)),
  );

  /// 3. Phone-verified club election — single choice, results after close.
  static final clubElection = VotingEvent(
    id: 'ev_club',
    publicId: 'cascade-cc-president',
    title: 'Cascade Cycling Club — President Election',
    shortDescription: 'Elect the club president for the 2026–2027 season.',
    longDescription:
        'The president sets the ride calendar, manages the budget, and '
        'represents the club with the city. The elected term runs October 2026 '
        'through September 2027. Phone verification keeps this to one ballot '
        'per member device.',
    category: EventCategory.club,
    coverSeed: 2,
    coverEmoji: '🚴',
    location: 'Seattle, WA',
    organizerName: 'Cascade Cycling Club',
    visibility: EventVisibility.unlisted,
    rules: const VotingRules(ballotType: BallotType.singleChoice),
    verificationLevel: VerificationLevel.phone,
    resultVisibility: ResultVisibility.afterClose,
    status: EventStatus.open,
    startsAt: _now.subtract(const Duration(hours: 12)),
    endsAt: _now.add(const Duration(days: 2, hours: 3)),
    totalBallots: 128,
    candidates: _candidates([
      (
        'Dana Kim',
        'Current vice president',
        'Six years in the club. Wants to double beginner rides and secure a permanent clubhouse lease.'
      ),
      (
        'Marcus Bell',
        'Ride captain',
        'Focused on safety training, better route signage, and a mentorship pairing for new riders.'
      ),
      (
        'Aisha Thompson',
        'Treasurer, 3 years',
        'Plans transparent budgeting, gear subsidies for youth members, and two charity century rides.'
      ),
    ]),
    createdAt: _now.subtract(const Duration(days: 14)),
  );

  /// 4. Ranked-choice event — open.
  static final rankedVote = VotingEvent(
    id: 'ev_mural',
    publicId: 'harbor-mural',
    title: 'Harbor District Mural: Rank the Designs',
    shortDescription: 'Rank five finalist designs for the 40-foot harbor wall.',
    longDescription:
        'Five artists made the final round. Rank the designs in your order of '
        'preference. If no design wins a majority of first choices, the lowest '
        'design is eliminated and its ballots count for their next choice — so '
        'your full ranking matters.',
    category: EventCategory.community,
    coverSeed: 3,
    coverEmoji: '🎨',
    location: 'Harbor District, Oakland',
    organizerName: 'Harbor Arts Council',
    visibility: EventVisibility.public,
    rules: const VotingRules(
      ballotType: BallotType.rankedChoice,
      requireFullRanking: false,
    ),
    verificationLevel: VerificationLevel.basicInstall,
    resultVisibility: ResultVisibility.live,
    status: EventStatus.open,
    startsAt: _now.subtract(const Duration(days: 2)),
    endsAt: _now.add(const Duration(days: 9)),
    totalBallots: 289,
    candidates: _candidates([
      (
        'Tidal Bloom',
        'by R. Fontaine',
        'Oversized native wildflowers dissolving into ocean waves, painted in a saturated dawn palette.'
      ),
      (
        'Shipwrights',
        'by J. Achebe',
        'A tribute to the harbor\'s boatbuilding era, weaving portraits of dockworkers into rigging lines.'
      ),
      (
        'Migration',
        'by K. Sato',
        'A flock of pelicans crossing an abstract tide chart of the bay, using reflective paint for dusk.'
      ),
      (
        'Neighborhood Quilt',
        'by D. Reyes',
        'Geometric panels contributed by 30 local families, unified by a shared color thread.'
      ),
      (
        'Under the Surface',
        'by M. Laurent',
        'A cutaway of harbor water showing kelp, seals, and the pilings of the old pier.'
      ),
    ]),
    createdAt: _now.subtract(const Duration(days: 8)),
  );

  /// 5. Closed event with final results.
  static final closedEvent = VotingEvent(
    id: 'ev_bookclub',
    publicId: 'pageturners-spring',
    title: 'Page Turners: Spring Book Selection',
    shortDescription: 'The club picked its April–June read.',
    longDescription:
        'Voting closed on March 20. "The Lantern Keepers" won with 41% of '
        'ballots and will be our spring read. Thanks to all 63 members who voted.',
    category: EventCategory.club,
    coverSeed: 4,
    coverEmoji: '📚',
    organizerName: 'Page Turners Book Club',
    visibility: EventVisibility.public,
    rules: const VotingRules(ballotType: BallotType.singleChoice),
    verificationLevel: VerificationLevel.basicInstall,
    resultVisibility: ResultVisibility.afterClose,
    status: EventStatus.closed,
    startsAt: _now.subtract(const Duration(days: 40)),
    endsAt: _now.subtract(const Duration(days: 12)),
    totalBallots: 63,
    candidates: _candidates([
      (
        'The Lantern Keepers',
        'Historical fiction',
        'Three generations of lighthouse keepers on a remote Scottish island.'
      ),
      (
        'Glass Cities',
        'Sci-fi',
        'A climate architect rebuilds a flooded metropolis from memory.'
      ),
      (
        'What the River Knows',
        'Mystery',
        'A retired detective returns to the town that never solved its only cold case.'
      ),
      (
        'Salt & Smoke',
        'Memoir',
        'A chef traces her family across three continents through ten recipes.'
      ),
    ]),
    createdAt: _now.subtract(const Duration(days: 45)),
  );

  /// 6. Draft organizer event — not yet published.
  static final draftEvent = VotingEvent(
    id: 'ev_draft',
    publicId: 'draft-hackday',
    title: 'Hack Day Project Awards',
    shortDescription: 'Vote for the best demo at Friday\'s hack day.',
    category: EventCategory.workplace,
    coverSeed: 5,
    coverEmoji: '🏆',
    organizerName: 'Aster Labs People Team',
    visibility: EventVisibility.unlisted,
    rules: const VotingRules(ballotType: BallotType.singleChoice),
    verificationLevel: VerificationLevel.verifiedInstall,
    resultVisibility: ResultVisibility.afterClose,
    status: EventStatus.draft,
    candidates: _candidates([
      (
        'Team Nimbus',
        'Weather-aware standup bot',
        'Rearranges standup order based on who is blocked.'
      ),
      (
        'Team Quokka',
        'Meeting cost ticker',
        'Live counter of what each meeting costs as it runs.'
      ),
    ]),
    createdAt: _now.subtract(const Duration(days: 1)),
  );

  static List<VotingEvent> all() => [
        communityAward,
        employeePoll,
        clubElection,
        rankedVote,
        closedEvent,
        draftEvent,
      ];

  /// Events owned by the demo organizer account.
  static Set<String> organizerOwnedIds() =>
      {employeePoll.id, draftEvent.id, closedEvent.id, communityAward.id};

  static List<ActivityItem> activity() => [
        ActivityItem(
          id: 'act_1',
          kind: ActivityKind.closingSoon,
          title: 'Offsite poll closes in 6 days',
          body: '47 ballots so far. Share the link again to nudge the team.',
          occurredAt: _now.subtract(const Duration(hours: 2)),
          eventId: employeePoll.id,
        ),
        ActivityItem(
          id: 'act_2',
          kind: ActivityKind.suspiciousActivity,
          title: 'Unusual voting pattern on Star Award',
          body:
              '9 ballots arrived from similar installations within one minute. '
              'Review the indicators in analytics.',
          occurredAt: _now.subtract(const Duration(hours: 7)),
          eventId: communityAward.id,
        ),
        ActivityItem(
          id: 'act_3',
          kind: ActivityKind.eventPublished,
          title: 'Star Award is live',
          body: 'Your event was published and is discoverable in search.',
          occurredAt: _now.subtract(const Duration(days: 3)),
          eventId: communityAward.id,
          read: true,
        ),
        ActivityItem(
          id: 'act_4',
          kind: ActivityKind.resultsFinalized,
          title: 'Spring Book Selection results are final',
          body: 'The Lantern Keepers won with 26 of 63 ballots.',
          occurredAt: _now.subtract(const Duration(days: 12)),
          eventId: closedEvent.id,
          read: true,
        ),
      ];

  /// Valid invitation tokens for private/unlisted flows in development.
  static const inviteTokens = {'demo-invite-2026': 'aster-offsite'};
}

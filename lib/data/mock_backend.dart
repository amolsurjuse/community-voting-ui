import 'dart:async';
import 'dart:math';

import '../domain/models/activity.dart';
import '../domain/models/analytics.dart';
import '../domain/models/ballot.dart';
import '../domain/models/enums.dart';
import '../domain/models/event.dart';
import '../domain/models/organizer.dart';
import '../domain/models/results.dart';
import 'ranked_choice_counter.dart';
import 'seed_data.dart';

/// Shared in-memory backend state. All mock repositories read and mutate this
/// single store so the app behaves consistently across screens.
class MockBackend {
  MockBackend({Random? random}) : _random = random ?? Random(7) {
    for (final event in SeedData.all()) {
      _events[event.id] = event;
      _voteCounts[event.id] = _seedTallies(event);
    }
    _activity.addAll(SeedData.activity());
  }

  final Random _random;
  final Map<String, VotingEvent> _events = {};
  final Map<String, Map<String, int>> _voteCounts = {};
  final Map<String, BallotReceipt> _receiptsByEvent = {};
  final Map<String, BallotSubmissionResult> _resultsByClientToken = {};
  final List<ActivityItem> _activity = [];
  final List<String> _recentEventIds = [];
  final Set<String> _ownedEventIds = SeedData.organizerOwnedIds();

  Organizer? currentOrganizer;
  String? pendingEmailCode;
  String? pendingPhoneCode;

  /// When true the next submit call fails with an unknown outcome once, to
  /// exercise the retry-safe path. Toggle from dev tools/tests.
  bool simulateNetworkFlakeOnce = false;

  final _eventsController =
      StreamController<List<VotingEvent>>.broadcast(sync: true);
  final _activityController =
      StreamController<List<ActivityItem>>.broadcast(sync: true);

  Map<String, VotingEvent> get events => _events;
  List<ActivityItem> get activity => List.unmodifiable(_activity);
  Set<String> get ownedEventIds => _ownedEventIds;
  List<String> get recentEventIds => List.unmodifiable(_recentEventIds);

  Stream<List<VotingEvent>> get organizerEventsStream async* {
    yield _organizerEvents();
    yield* _eventsController.stream;
  }

  Stream<List<ActivityItem>> get activityStream async* {
    yield activity;
    yield* _activityController.stream;
  }

  List<VotingEvent> _organizerEvents() {
    final list = _events.values
        .where((e) => _ownedEventIds.contains(e.id))
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(2020))
          .compareTo(a.createdAt ?? DateTime(2020)));
    return list;
  }

  void notifyEventsChanged() => _eventsController.add(_organizerEvents());

  void addActivity(ActivityItem item) {
    _activity.insert(0, item);
    _activityController.add(activity);
  }

  void markActivityRead() {
    for (var i = 0; i < _activity.length; i++) {
      _activity[i] = _activity[i].copyWith(read: true);
    }
    _activityController.add(activity);
  }

  void upsertEvent(VotingEvent event, {bool owned = true}) {
    _events[event.id] = event;
    _voteCounts.putIfAbsent(event.id, () => _seedTallies(event));
    if (owned) _ownedEventIds.add(event.id);
    notifyEventsChanged();
  }

  void rememberRecent(String publicId) {
    _recentEventIds
      ..remove(publicId)
      ..insert(0, publicId);
    if (_recentEventIds.length > 10) _recentEventIds.removeLast();
  }

  BallotReceipt? receiptFor(String eventId) => _receiptsByEvent[eventId];

  Map<String, int> tallies(String eventId) =>
      Map.unmodifiable(_voteCounts[eventId] ?? const {});

  Map<String, int> _seedTallies(VotingEvent event) {
    final counts = <String, int>{};
    if (event.totalBallots == 0 || event.candidates.isEmpty) {
      for (final c in event.candidates) {
        counts[c.id] = 0;
      }
      return counts;
    }
    // Deterministic plausible distribution that sums to totalBallots.
    var remaining = event.totalBallots;
    final sorted = event.activeCandidates;
    for (var i = 0; i < sorted.length; i++) {
      final isLast = i == sorted.length - 1;
      final share = isLast
          ? remaining
          : (remaining * (0.2 + _random.nextDouble() * 0.25)).round();
      counts[sorted[i].id] = min(share, remaining);
      remaining -= counts[sorted[i].id]!;
    }
    return counts;
  }

  /// Registers one live vote for a random-but-weighted candidate; used by the
  /// results stream to simulate other participants voting.
  void simulateIncomingVote(String eventId) {
    final event = _events[eventId];
    final counts = _voteCounts[eventId];
    if (event == null || counts == null || !event.isOpen) return;
    final candidates = event.activeCandidates;
    if (candidates.isEmpty) return;
    final pick = candidates[_random.nextInt(candidates.length)];
    counts[pick.id] = (counts[pick.id] ?? 0) + 1;
    _events[eventId] = event.copyWith(totalBallots: event.totalBallots + 1);
  }

  BallotSubmissionResult recordBallot(BallotDraft draft) {
    final token = draft.clientToken;
    // Idempotency: replay the original outcome for a retried token.
    if (token != null && _resultsByClientToken.containsKey(token)) {
      return _resultsByClientToken[token]!;
    }

    final event = _events[draft.eventId];
    late final BallotSubmissionResult outcome;
    if (event == null) {
      outcome = const BallotInvalid('This event no longer exists.');
    } else if (event.isClosed ||
        (event.endsAt != null && event.endsAt!.isBefore(DateTime.now()))) {
      outcome = const BallotEventClosed();
    } else if (_receiptsByEvent.containsKey(draft.eventId)) {
      outcome = BallotAlreadyCast(_receiptsByEvent[draft.eventId]);
    } else {
      final validation =
          draft.validate(event.rules, event.activeCandidates.length);
      if (!validation.isValid) {
        outcome = BallotInvalid(validation.message);
      } else {
        final counts = _voteCounts[draft.eventId]!;
        if (draft.ballotType == BallotType.rankedChoice) {
          // Tally first preference; full ranking feeds the round computation.
          counts[draft.selections.first] =
              (counts[draft.selections.first] ?? 0) + 1;
        } else {
          for (final id in draft.selections) {
            counts[id] = (counts[id] ?? 0) + 1;
          }
        }
        _events[draft.eventId] =
            event.copyWith(totalBallots: event.totalBallots + 1);
        final receipt = BallotReceipt(
          receiptCode: _receiptCode(),
          eventId: draft.eventId,
          acceptedAt: DateTime.now(),
        );
        _receiptsByEvent[draft.eventId] = receipt;
        outcome = BallotAccepted(receipt);
      }
    }
    if (token != null) _resultsByClientToken[token] = outcome;
    return outcome;
  }

  String _receiptCode() {
    const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final code =
        List.generate(8, (_) => alphabet[_random.nextInt(alphabet.length)])
            .join();
    return '${code.substring(0, 4)}-${code.substring(4)}';
  }

  ResultsSnapshot snapshot(String eventId) {
    final event = _events[eventId]!;
    final counts = _voteCounts[eventId]!;
    final tallies = [
      for (final c in event.activeCandidates)
        CandidateTally(candidateId: c.id, votes: counts[c.id] ?? 0),
    ];
    final belowThreshold = event.minResultThreshold > 0 &&
        event.totalBallots < event.minResultThreshold;
    return ResultsSnapshot(
      eventId: eventId,
      totalBallots: event.totalBallots,
      tallies: tallies,
      rankedRounds: event.rules.ballotType == BallotType.rankedChoice
          ? RankedChoiceCounter.computeRounds(
              candidates: event.activeCandidates,
              firstPreferences: counts,
              seed: event.id.hashCode,
            )
          : const [],
      updatedAt: DateTime.now(),
      isFinal: event.isClosed,
      belowThreshold: belowThreshold,
    );
  }

  EventAnalytics analyticsFor(String eventId) {
    final event = _events[eventId]!;
    final total = event.totalBallots;
    final hours = 24;
    final buckets = List<int>.generate(hours, (i) {
      final weight = 0.4 + 0.6 * sin(pi * i / hours);
      return max(
          0, (total / hours * weight * (0.6 + _random.nextDouble())).round());
    });
    final started = (total * 1.35).round();
    final completed = (total * 1.12).round();
    return EventAnalytics(
      eventId: eventId,
      acceptedBallots: total,
      participationByHour: buckets,
      verificationStarted: started,
      verificationCompleted: completed,
      failedVerificationAttempts: max(0, started - completed),
      suspiciousIndicators: eventId == 'ev_award'
          ? const [
              '9 ballots from similar installations within 60 seconds',
              'Repeated verification failures from one network',
            ]
          : const [],
      platformSplit:
          total >= 50 ? const {'iOS': 0.58, 'Android': 0.42} : const {},
    );
  }

  void dispose() {
    _eventsController.close();
    _activityController.close();
  }
}

/// User-facing outcomes for auth simulation.
class MockCredentials {
  MockCredentials._();

  /// Any 6-digit code ending in an even digit is accepted, to make manual
  /// testing easy while still exercising the failure path.
  static bool isValidOtp(String code) =>
      RegExp(r'^\d{6}$').hasMatch(code) && int.parse(code[5]).isEven;

  static const demoHint =
      'Development build: any 6-digit code ending in an even digit works, e.g. 111112.';
}

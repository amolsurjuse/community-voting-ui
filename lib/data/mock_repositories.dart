import 'dart:async';
import 'dart:math';

import '../core/storage/secure_store.dart';
import '../domain/models/activity.dart';
import '../domain/models/analytics.dart';
import '../domain/models/ballot.dart';
import '../domain/models/enums.dart';
import '../domain/models/event.dart';
import '../domain/models/organizer.dart';
import '../domain/models/results.dart';
import '../domain/repositories.dart';
import 'mock_backend.dart';
import 'seed_data.dart';

const _latency = Duration(milliseconds: 450);

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._backend, this._secureStore);

  final MockBackend _backend;
  final SecureStore _secureStore;

  @override
  Organizer? get current => _backend.currentOrganizer;

  @override
  Future<Organizer?> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final token = await _secureStore.read(SecureKey.organizerAuthToken);
    if (token == null) return null;
    return _backend.currentOrganizer;
  }

  @override
  Future<Organizer> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future<void>.delayed(_latency);
    final organizer = Organizer(
      id: 'org_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      phone: _mask(phone),
    );
    _backend.currentOrganizer = organizer;
    _backend.pendingEmailCode = '000000'; // simulated email delivery
    await _secureStore.write(
        SecureKey.organizerAuthToken, 'mock-token-${organizer.id}');
    return organizer;
  }

  @override
  Future<void> resendEmailCode() async {
    await Future<void>.delayed(_latency);
    _backend.pendingEmailCode = '000000';
  }

  @override
  Future<Organizer> verifyEmail(String code) async {
    await Future<void>.delayed(_latency);
    final organizer = _backend.currentOrganizer;
    if (organizer == null)
      throw const RepositoryException('Session expired. Sign in again.');
    if (!MockCredentials.isValidOtp(code)) {
      throw const RepositoryException(
          'That code is not valid. Check the latest email and try again.');
    }
    return _backend.currentOrganizer = organizer.copyWith(emailVerified: true);
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    await Future<void>.delayed(_latency);
    final organizer = _backend.currentOrganizer;
    if (organizer != null) {
      _backend.currentOrganizer = organizer.copyWith(phone: _mask(phone));
    }
    _backend.pendingPhoneCode = '000000';
  }

  @override
  Future<Organizer> verifyPhoneOtp(String code) async {
    await Future<void>.delayed(_latency);
    final organizer = _backend.currentOrganizer;
    if (organizer == null)
      throw const RepositoryException('Session expired. Sign in again.');
    if (!MockCredentials.isValidOtp(code)) {
      throw const RepositoryException(
          'That code did not match. Try again or resend.');
    }
    return _backend.currentOrganizer = organizer.copyWith(phoneVerified: true);
  }

  @override
  Future<void> signOut() async {
    _backend.currentOrganizer = null;
    await _secureStore.delete(SecureKey.organizerAuthToken);
  }

  String _mask(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '•••';
    return '••• ••• ${digits.substring(digits.length - 4)}';
  }
}

class MockEventRepository implements EventRepository {
  MockEventRepository(this._backend);

  final MockBackend _backend;
  final Random _random = Random();

  @override
  Stream<List<VotingEvent>> watchOrganizerEvents() =>
      _backend.organizerEventsStream;

  @override
  Future<VotingEvent?> getByPublicId(String publicId) async {
    await Future<void>.delayed(_latency);
    final matches = _backend.events.values.where((e) => e.publicId == publicId);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<VotingEvent> saveDraft(VotingEvent draft) async {
    await Future<void>.delayed(_latency);
    _backend.upsertEvent(draft);
    return draft;
  }

  @override
  Future<VotingEvent> publish(String eventId) async {
    await Future<void>.delayed(_latency);
    final event = _require(eventId);
    if (event.activeCandidates.length < 2) {
      throw const RepositoryException(
          'Add at least two options before publishing.');
    }
    final now = DateTime.now();
    final scheduled = event.startsAt != null && event.startsAt!.isAfter(now);
    final published = event.copyWith(
      status: scheduled ? EventStatus.scheduled : EventStatus.open,
      startsAt: event.startsAt ?? now,
    );
    _backend.upsertEvent(published);
    _backend.addActivity(ActivityItem(
      id: 'act_pub_${now.millisecondsSinceEpoch}',
      kind: ActivityKind.eventPublished,
      title: '${published.title} is ${scheduled ? 'scheduled' : 'live'}',
      body: scheduled
          ? 'Voting opens automatically at the scheduled start time.'
          : 'Participants can vote now. Share the link to get started.',
      occurredAt: now,
      eventId: published.id,
    ));
    return published;
  }

  @override
  Future<VotingEvent> close(String eventId) async {
    await Future<void>.delayed(_latency);
    final closed = _require(eventId).copyWith(
      status: EventStatus.closed,
      endsAt: DateTime.now(),
    );
    _backend.upsertEvent(closed);
    _backend.addActivity(ActivityItem(
      id: 'act_close_${DateTime.now().millisecondsSinceEpoch}',
      kind: ActivityKind.eventClosed,
      title: '${closed.title} has closed',
      body:
          '${closed.totalBallots} ballots were accepted. Results are being finalized.',
      occurredAt: DateTime.now(),
      eventId: closed.id,
    ));
    return closed;
  }

  @override
  Future<VotingEvent> archive(String eventId) async {
    await Future<void>.delayed(_latency);
    final archived = _require(eventId).copyWith(status: EventStatus.archived);
    _backend.upsertEvent(archived);
    return archived;
  }

  @override
  Future<VotingEvent> duplicate(String eventId) async {
    await Future<void>.delayed(_latency);
    final source = _require(eventId);
    final id = 'ev_${DateTime.now().millisecondsSinceEpoch}';
    final copy = VotingEvent(
      id: id,
      publicId: '${source.publicId}-copy${_random.nextInt(90) + 10}',
      title: '${source.title} (copy)',
      shortDescription: source.shortDescription,
      longDescription: source.longDescription,
      category: source.category,
      coverSeed: source.coverSeed,
      coverEmoji: source.coverEmoji,
      location: source.location,
      organizerName: source.organizerName,
      visibility: source.visibility,
      rules: source.rules,
      verificationLevel: source.verificationLevel,
      resultVisibility: source.resultVisibility,
      status: EventStatus.draft,
      candidates: source.candidates,
      createdAt: DateTime.now(),
    );
    _backend.upsertEvent(copy);
    return copy;
  }

  @override
  Future<List<VotingEvent>> discover(DiscoverFilters filters,
      {int page = 0}) async {
    await Future<void>.delayed(_latency);
    final query = filters.query.trim().toLowerCase();
    final results = _backend.events.values.where((e) {
      if (e.visibility != EventVisibility.public) return false;
      if (e.isDraft) return false;
      if (filters.category != null && e.category != filters.category)
        return false;
      if (filters.verificationLevel != null &&
          e.verificationLevel != filters.verificationLevel) {
        return false;
      }
      if (filters.ballotType != null &&
          e.rules.ballotType != filters.ballotType) {
        return false;
      }
      if (filters.resultVisibility != null &&
          e.resultVisibility != filters.resultVisibility) {
        return false;
      }
      if (query.isNotEmpty) {
        final haystack =
            '${e.title} ${e.shortDescription} ${e.organizerName}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.totalBallots.compareTo(a.totalBallots));
    // Simple pagination over the in-memory list.
    const pageSize = 10;
    final start = page * pageSize;
    if (start >= results.length) return const [];
    return results.sublist(start, min(start + pageSize, results.length));
  }

  @override
  Future<List<VotingEvent>> trending() async =>
      (await discover(const DiscoverFilters())).take(4).toList();

  @override
  Future<List<VotingEvent>> closingSoon() async {
    final open = await discover(const DiscoverFilters());
    return (open.where((e) => e.isOpen && e.endsAt != null).toList()
          ..sort((a, b) => a.endsAt!.compareTo(b.endsAt!)))
        .take(4)
        .toList();
  }

  @override
  Future<List<VotingEvent>> newlyPublished() async {
    final open = await discover(const DiscoverFilters());
    return (open.where((e) => !e.isClosed).toList()
          ..sort((a, b) => (b.startsAt ?? DateTime(2020))
              .compareTo(a.startsAt ?? DateTime(2020))))
        .take(4)
        .toList();
  }

  @override
  Future<VotingEvent?> redeemInvitation(String token) async {
    await Future<void>.delayed(_latency);
    final publicId = SeedData.inviteTokens[token];
    if (publicId == null) return null;
    return getByPublicId(publicId);
  }

  VotingEvent _require(String eventId) {
    final event = _backend.events[eventId];
    if (event == null) throw const RepositoryException('Event not found.');
    return event;
  }
}

class MockBallotRepository implements BallotRepository {
  MockBallotRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<BallotReceipt?> existingReceipt(String eventId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _backend.receiptFor(eventId);
  }

  @override
  Future<BallotSubmissionResult> submit(BallotDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (_backend.simulateNetworkFlakeOnce) {
      _backend.simulateNetworkFlakeOnce = false;
      return const BallotOutcomeUnknown();
    }
    return _backend.recordBallot(draft);
  }

  @override
  Future<List<String>> recentEventIds() async => _backend.recentEventIds;

  @override
  Future<void> rememberEvent(String publicId) async =>
      _backend.rememberRecent(publicId);
}

class MockResultsRepository implements ResultsRepository {
  MockResultsRepository(this._backend);

  final MockBackend _backend;

  @override
  Stream<ResultsSnapshot> watchResults(String eventId) async* {
    yield _backend.snapshot(eventId);
    // Simulate other participants voting while the event is open.
    yield* Stream.periodic(const Duration(seconds: 4), (_) {
      _backend.simulateIncomingVote(eventId);
      return _backend.snapshot(eventId);
    });
  }
}

class MockAnalyticsRepository implements AnalyticsRepository {
  MockAnalyticsRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<EventAnalytics> summary(String eventId) async {
    await Future<void>.delayed(_latency);
    return _backend.analyticsFor(eventId);
  }

  @override
  Future<void> requestExport(String eventId) async {
    await Future<void>.delayed(_latency);
    _backend.addActivity(ActivityItem(
      id: 'act_export_${DateTime.now().millisecondsSinceEpoch}',
      kind: ActivityKind.exportReady,
      title: 'Results export ready',
      body: 'Your CSV export has been generated and is ready to download.',
      occurredAt: DateTime.now(),
      eventId: eventId,
    ));
  }
}

class MockActivityRepository implements ActivityRepository {
  MockActivityRepository(this._backend);

  final MockBackend _backend;

  @override
  Stream<List<ActivityItem>> watchActivity() => _backend.activityStream;

  @override
  Future<void> markAllRead() async => _backend.markActivityRead();
}

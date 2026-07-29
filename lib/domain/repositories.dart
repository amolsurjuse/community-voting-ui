import 'models/activity.dart';
import 'models/analytics.dart';
import 'models/ballot.dart';
import 'models/enums.dart';
import 'models/event.dart';
import 'models/organizer.dart';
import 'models/results.dart';

/// Thrown by repositories for recoverable failures with a user-safe message.
class RepositoryException implements Exception {
  const RepositoryException(this.message, {this.isNetwork = false});
  final String message;
  final bool isNetwork;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  Future<Organizer?> restoreSession();
  Future<Organizer> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });
  Future<void> resendEmailCode();
  Future<Organizer> verifyEmail(String code);
  Future<void> sendPhoneOtp(String phone);
  Future<Organizer> verifyPhoneOtp(String code);
  Future<void> signOut();
  Organizer? get current;
}

class DiscoverFilters {
  const DiscoverFilters({
    this.query = '',
    this.category,
    this.verificationLevel,
    this.ballotType,
    this.resultVisibility,
  });

  final String query;
  final EventCategory? category;
  final VerificationLevel? verificationLevel;
  final BallotType? ballotType;
  final ResultVisibility? resultVisibility;

  bool get isEmpty =>
      query.isEmpty &&
      category == null &&
      verificationLevel == null &&
      ballotType == null &&
      resultVisibility == null;
}

abstract class EventRepository {
  /// Organizer's own events (all statuses), newest first.
  Stream<List<VotingEvent>> watchOrganizerEvents();

  Future<VotingEvent?> getByPublicId(String publicId);
  Future<VotingEvent> saveDraft(VotingEvent draft);
  Future<VotingEvent> publish(String eventId);
  Future<VotingEvent> close(String eventId);
  Future<VotingEvent> archive(String eventId);
  Future<VotingEvent> duplicate(String eventId);

  /// Paginated public discovery. Only [EventVisibility.public] events.
  Future<List<VotingEvent>> discover(DiscoverFilters filters, {int page = 0});

  Future<List<VotingEvent>> trending();
  Future<List<VotingEvent>> closingSoon();
  Future<List<VotingEvent>> newlyPublished();

  /// Resolve a private invitation token to an event, or null when invalid.
  Future<VotingEvent?> redeemInvitation(String token);
}

abstract class BallotRepository {
  /// Whether this installation already holds an accepted ballot.
  Future<BallotReceipt?> existingReceipt(String eventId);

  /// Idempotent submit keyed by [BallotDraft.clientToken].
  Future<BallotSubmissionResult> submit(BallotDraft draft);

  /// Events this installation has interacted with (local recent history).
  Future<List<String>> recentEventIds();
  Future<void> rememberEvent(String publicId);
}

abstract class ResultsRepository {
  /// Emits the current snapshot immediately, then live updates while open.
  Stream<ResultsSnapshot> watchResults(String eventId);
}

abstract class AnalyticsRepository {
  Future<EventAnalytics> summary(String eventId);
  Future<void> requestExport(String eventId);
}

abstract class ActivityRepository {
  Stream<List<ActivityItem>> watchActivity();
  Future<void> markAllRead();
}

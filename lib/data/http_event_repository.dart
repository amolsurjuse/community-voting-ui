import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/models/candidate.dart';
import '../domain/models/enums.dart';
import '../domain/models/event.dart';
import '../domain/repositories.dart';

/// Participant event reads use the service API. Unsupported server operations
/// fail explicitly instead of silently returning seeded mock data.
class HttpEventRepository implements EventRepository {
  HttpEventRepository({
    required Uri gatewayBaseUri,
    http.Client? client,
  })  : _baseUri = gatewayBaseUri,
        _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  @override
  Future<VotingEvent?> getByPublicId(String publicId) async {
    final response = await _client.get(
      _baseUri.resolve('/community-voting/v1/public/events/$publicId'),
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RepositoryException(
        'The event could not be loaded (${response.statusCode}).',
        isNetwork: response.statusCode >= 500,
      );
    }
    return _event(jsonDecode(response.body) as Map<String, dynamic>);
  }

  VotingEvent _event(Map<String, dynamic> value) {
    final rules = value['rules'] as Map<String, dynamic>;
    final candidates = value['candidates'] as List<dynamic>;
    return VotingEvent(
      id: value['id'] as String,
      publicId: value['publicId'] as String,
      title: value['title'] as String,
      shortDescription: value['shortDescription'] as String? ?? '',
      longDescription: value['longDescription'] as String? ?? '',
      organizerName: value['organizerName'] as String,
      visibility: _visibility(value['visibility'] as String),
      verificationLevel: _verification(value['verificationLevel'] as String),
      resultVisibility: _resultVisibility(value['resultVisibility'] as String),
      status: _status(value['status'] as String),
      startsAt: DateTime.parse(value['startsAt'] as String),
      endsAt: DateTime.parse(value['endsAt'] as String),
      rules: VotingRules(
        ballotType: _ballotType(rules['ballotType'] as String),
        minSelections: rules['minSelections'] as int,
        maxSelections: rules['maxSelections'] as int,
        requireFullRanking: rules['requireFullRanking'] as bool,
      ),
      candidates: candidates.map((item) {
        final candidate = item as Map<String, dynamic>;
        return Candidate(
          id: candidate['id'] as String,
          name: candidate['name'] as String,
          order: candidate['order'] as int,
          active: candidate['active'] as bool,
        );
      }).toList(growable: false),
    );
  }

  EventVisibility _visibility(String value) => switch (value) {
        'PUBLIC' => EventVisibility.public,
        'UNLISTED' => EventVisibility.unlisted,
        _ => EventVisibility.private,
      };

  VerificationLevel _verification(String value) => switch (value) {
        'PHONE' => VerificationLevel.phone,
        'INVITATION' => VerificationLevel.invitation,
        'ORGANIZER_APPROVAL' => VerificationLevel.organizerApproval,
        'ATTESTED_INSTALLATION' => VerificationLevel.verifiedInstall,
        _ => VerificationLevel.basicInstall,
      };

  ResultVisibility _resultVisibility(String value) => switch (value) {
        'LIVE' => ResultVisibility.live,
        'AFTER_VOTE' => ResultVisibility.afterVote,
        'ORGANIZER_ONLY' => ResultVisibility.organizerOnly,
        _ => ResultVisibility.afterClose,
      };

  EventStatus _status(String value) => switch (value) {
        'DRAFT' => EventStatus.draft,
        'SCHEDULED' => EventStatus.scheduled,
        'OPEN' => EventStatus.open,
        'ARCHIVED' => EventStatus.archived,
        _ => EventStatus.closed,
      };

  BallotType _ballotType(String value) => switch (value) {
        'SINGLE' => BallotType.singleChoice,
        'MULTIPLE' => BallotType.multipleChoice,
        'RANKED' => BallotType.rankedChoice,
        _ => BallotType.score,
      };

  @override
  Future<VotingEvent> archive(String eventId) => _unsupported();
  @override
  Future<VotingEvent> close(String eventId) => _unsupported();
  @override
  Future<List<VotingEvent>> closingSoon() => _unsupported();
  @override
  Future<List<VotingEvent>> discover(DiscoverFilters filters, {int page = 0}) =>
      _unsupported();
  @override
  Future<VotingEvent> duplicate(String eventId) => _unsupported();
  @override
  Future<List<VotingEvent>> newlyPublished() => _unsupported();
  @override
  Future<VotingEvent> publish(String eventId) => _unsupported();
  @override
  Future<VotingEvent?> redeemInvitation(String token) =>
      _unsupported();
  @override
  Future<VotingEvent> saveDraft(VotingEvent draft) =>
      _unsupported();
  @override
  Future<List<VotingEvent>> trending() => _unsupported();
  @override
  Stream<List<VotingEvent>> watchOrganizerEvents() => Stream.error(
        const RepositoryException(
          'Organizer event APIs are not available on the server yet.',
        ),
      );

  Future<T> _unsupported<T>() => Future.error(
        const RepositoryException(
          'This operation is not available on the server yet.',
        ),
      );
}

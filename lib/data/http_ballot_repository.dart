import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/storage/secure_store.dart';
import '../domain/models/ballot.dart';
import '../domain/models/enums.dart';
import '../domain/repositories.dart';

class HttpBallotRepository implements BallotRepository {
  HttpBallotRepository({
    required Uri gatewayBaseUri,
    required SecureStore secureStore,
    http.Client? client,
  })  : _baseUri = gatewayBaseUri,
        _secureStore = secureStore,
        _client = client ?? http.Client();

  final Uri _baseUri;
  final SecureStore _secureStore;
  final http.Client _client;
  final Map<String, BallotReceipt> _receipts = {};
  final List<String> _recentEvents = [];

  @override
  Future<BallotReceipt?> existingReceipt(String eventId) async =>
      _receipts[eventId];

  @override
  Future<BallotSubmissionResult> submit(BallotDraft draft) async {
    final idempotencyKey = draft.clientToken;
    if (idempotencyKey == null) {
      return const BallotInvalid('A retry-safe ballot token is required.');
    }
    try {
      final token = await _accessToken();
      final eligibility = await _post(
        '/community-voting/v1/events/${draft.eventId}/eligibility',
        token,
        const {},
      );
      final response = await _client.post(
        _baseUri.resolve(
          '/community-voting/v1/events/${draft.eventId}/ballots',
        ),
        headers: {
          'authorization': 'Bearer $token',
          'content-type': 'application/json',
          'idempotency-key': idempotencyKey,
        },
        body: jsonEncode({
          'credentialId': eligibility['credentialId'],
          'rulesVersion': eligibility['rulesVersion'],
          'candidateVersion': eligibility['candidateVersion'],
          'ballotType': _ballotType(draft.ballotType),
          'candidateIds': draft.selections,
        }),
      );
      final body = _body(response);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final receipt = BallotReceipt(
          receiptCode: body['receiptToken'] as String,
          eventId: draft.eventId,
          acceptedAt: DateTime.parse(body['acceptedTimeBucket'] as String),
        );
        _receipts[draft.eventId] = receipt;
        return BallotAccepted(receipt);
      }
      final code = body['code'];
      return switch (code) {
        'CREDENTIAL_ALREADY_CONSUMED' =>
          BallotAlreadyCast(_receipts[draft.eventId]),
        'EVENT_NOT_OPEN' => const BallotEventClosed(),
        _ => BallotInvalid(
            body['detail'] as String? ?? 'The ballot was rejected.',
          ),
      };
    } on SocketException {
      return const BallotOutcomeUnknown();
    } on http.ClientException {
      return const BallotOutcomeUnknown();
    } on FormatException {
      return const BallotOutcomeUnknown();
    } on RepositoryException catch (error) {
      return BallotInvalid(error.message);
    }
  }

  @override
  Future<List<String>> recentEventIds() async =>
      List.unmodifiable(_recentEvents);

  @override
  Future<void> rememberEvent(String publicId) async {
    _recentEvents.remove(publicId);
    _recentEvents.insert(0, publicId);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      _baseUri.resolve(path),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(body),
    );
    final decoded = _body(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RepositoryException(
        decoded['detail'] as String? ?? 'Eligibility could not be established.',
      );
    }
    return decoded;
  }

  Map<String, dynamic> _body(http.Response response) => response.body.isEmpty
      ? <String, dynamic>{}
      : jsonDecode(response.body) as Map<String, dynamic>;

  Future<String> _accessToken() async {
    final token = await _secureStore.read(SecureKey.organizerAuthToken);
    if (token == null) {
      throw const RepositoryException('Sign in to cast a ballot.');
    }
    return token;
  }

  String _ballotType(BallotType value) => switch (value) {
        BallotType.singleChoice => 'SINGLE',
        BallotType.multipleChoice => 'MULTIPLE',
        BallotType.rankedChoice => 'RANKED',
        BallotType.score => 'SCORE',
      };
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulsevote/core/storage/secure_store.dart';
import 'package:pulsevote/data/http_ballot_repository.dart';
import 'package:pulsevote/domain/models/ballot.dart';
import 'package:pulsevote/domain/models/enums.dart';

void main() {
  test('submits server-issued eligibility and UUID idempotency key', () async {
    final store = InMemorySecureStore();
    await store.write(SecureKey.organizerAuthToken, 'access-token');
    var eligibilityCalled = false;
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer access-token');
      if (request.url.path.endsWith('/eligibility')) {
        eligibilityCalled = true;
        return http.Response(
          jsonEncode({
            'credentialId': '101bf17a-84fa-4fa1-94db-c3bc4ee7289a',
            'rulesVersion': 3,
            'candidateVersion': 4,
          }),
          200,
        );
      }
      expect(request.headers['idempotency-key'],
          '9ea79804-52a9-4c47-8982-cffe41c67338');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['credentialId'], '101bf17a-84fa-4fa1-94db-c3bc4ee7289a');
      expect(body['rulesVersion'], 3);
      expect(body['candidateVersion'], 4);
      expect(body['ballotType'], 'SINGLE');
      return http.Response(
        jsonEncode({
          'receiptId': 'e89861db-f875-4dee-958d-96b3014b9776',
          'receiptToken': 'receipt-token',
          'acceptedTimeBucket': '2026-07-30T00:00:00Z',
          'replayed': false,
        }),
        201,
      );
    });
    final repository = HttpBallotRepository(
      gatewayBaseUri: Uri.parse('https://api.example.test'),
      secureStore: store,
      client: client,
    );

    final result = await repository.submit(
      const BallotDraft(
        eventId: '0b4e633d-c97f-4e42-ac73-e11d02d11494',
        ballotType: BallotType.singleChoice,
        selections: ['3202bd65-06af-4114-848c-424611129e71'],
        clientToken: '9ea79804-52a9-4c47-8982-cffe41c67338',
      ),
    );

    expect(eligibilityCalled, isTrue);
    expect(result, isA<BallotAccepted>());
    expect(
      await repository.existingReceipt(
        '0b4e633d-c97f-4e42-ac73-e11d02d11494',
      ),
      isNotNull,
    );
  });

  test('does not attempt an unauthenticated submission', () async {
    final repository = HttpBallotRepository(
      gatewayBaseUri: Uri.parse('https://api.example.test'),
      secureStore: InMemorySecureStore(),
      client: MockClient((_) => throw StateError('must not call server')),
    );

    final result = await repository.submit(
      const BallotDraft(
        eventId: '0b4e633d-c97f-4e42-ac73-e11d02d11494',
        ballotType: BallotType.singleChoice,
        selections: ['3202bd65-06af-4114-848c-424611129e71'],
        clientToken: '9ea79804-52a9-4c47-8982-cffe41c67338',
      ),
    );

    expect(result, isA<BallotInvalid>());
  });
}

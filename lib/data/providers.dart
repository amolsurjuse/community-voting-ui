import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/http/logging_http_client.dart';
import '../core/storage/secure_store.dart';
import '../core/storage/platform_secure_store.dart';
import '../domain/repositories.dart';
import 'mock_backend.dart';
import 'mock_repositories.dart';
import 'http_auth_repository.dart';
import 'http_ballot_repository.dart';
import 'http_event_repository.dart';
import 'unavailable_repositories.dart';

const _useRealApi = bool.fromEnvironment('USE_REAL_API', defaultValue: true);
const _gatewayUrl = String.fromEnvironment(
  'GATEWAY_BASE_URL',
  defaultValue: 'https://api.electrahub.net',
);

/// Shared HTTP client with request/response logging.
final httpClientProvider = Provider<http.Client>(
  (ref) => LoggingHttpClient(),
);

/// Composition root. Swap these providers to point the app at a real backend
/// without touching feature code.
final secureStoreProvider = Provider<SecureStore>(
  (ref) => _useRealApi
      ? const PlatformSecureStore(PlatformSecureStore.storage)
      : InMemorySecureStore(),
);

final mockBackendProvider = Provider<MockBackend>((ref) {
  final backend = MockBackend();
  ref.onDispose(backend.dispose);
  return backend;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => _useRealApi
      ? HttpAuthRepository(
          gatewayBaseUri: Uri.parse(_gatewayUrl),
          secureStore: ref.watch(secureStoreProvider),
          client: ref.watch(httpClientProvider),
        )
      : MockAuthRepository(
          ref.watch(mockBackendProvider),
          ref.watch(secureStoreProvider),
        ),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) {
    final fallback = MockEventRepository(ref.watch(mockBackendProvider));
    return _useRealApi
        ? HttpEventRepository(
            gatewayBaseUri: Uri.parse(_gatewayUrl),
            client: ref.watch(httpClientProvider),
          )
        : fallback;
  },
);

final ballotRepositoryProvider = Provider<BallotRepository>(
  (ref) => _useRealApi
      ? HttpBallotRepository(
          gatewayBaseUri: Uri.parse(_gatewayUrl),
          secureStore: ref.watch(secureStoreProvider),
          client: ref.watch(httpClientProvider),
        )
      : MockBallotRepository(ref.watch(mockBackendProvider)),
);

final resultsRepositoryProvider = Provider<ResultsRepository>(
  (ref) => _useRealApi
      ? const UnavailableResultsRepository()
      : MockResultsRepository(ref.watch(mockBackendProvider)),
);

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => _useRealApi
      ? const UnavailableAnalyticsRepository()
      : MockAnalyticsRepository(ref.watch(mockBackendProvider)),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => _useRealApi
      ? const UnavailableActivityRepository()
      : MockActivityRepository(ref.watch(mockBackendProvider)),
);

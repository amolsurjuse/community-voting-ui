import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/secure_store.dart';
import '../core/storage/platform_secure_store.dart';
import '../domain/repositories.dart';
import 'mock_backend.dart';
import 'mock_repositories.dart';
import 'http_auth_repository.dart';
import 'http_ballot_repository.dart';
import 'http_event_repository.dart';

const _useRealApi = bool.fromEnvironment('USE_REAL_API');
const _gatewayUrl = String.fromEnvironment(
  'GATEWAY_BASE_URL',
  defaultValue: 'http://10.0.2.2:8090',
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
            fallback: fallback,
          )
        : fallback;
  },
);

final ballotRepositoryProvider = Provider<BallotRepository>(
  (ref) => _useRealApi
      ? HttpBallotRepository(
          gatewayBaseUri: Uri.parse(_gatewayUrl),
          secureStore: ref.watch(secureStoreProvider),
        )
      : MockBallotRepository(ref.watch(mockBackendProvider)),
);

final resultsRepositoryProvider = Provider<ResultsRepository>(
  (ref) => MockResultsRepository(ref.watch(mockBackendProvider)),
);

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => MockAnalyticsRepository(ref.watch(mockBackendProvider)),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => MockActivityRepository(ref.watch(mockBackendProvider)),
);

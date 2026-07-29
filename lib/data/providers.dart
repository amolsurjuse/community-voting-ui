import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/secure_store.dart';
import '../domain/repositories.dart';
import 'mock_backend.dart';
import 'mock_repositories.dart';

/// Composition root. Swap these providers to point the app at a real backend
/// without touching feature code.
final secureStoreProvider =
    Provider<SecureStore>((ref) => InMemorySecureStore());

final mockBackendProvider = Provider<MockBackend>((ref) {
  final backend = MockBackend();
  ref.onDispose(backend.dispose);
  return backend;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(
    ref.watch(mockBackendProvider),
    ref.watch(secureStoreProvider),
  ),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => MockEventRepository(ref.watch(mockBackendProvider)),
);

final ballotRepositoryProvider = Provider<BallotRepository>(
  (ref) => MockBallotRepository(ref.watch(mockBackendProvider)),
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

import '../domain/models/activity.dart';
import '../domain/models/analytics.dart';
import '../domain/models/results.dart';
import '../domain/repositories.dart';

const _message = 'This API is not available on the server yet.';

class UnavailableResultsRepository implements ResultsRepository {
  const UnavailableResultsRepository();

  @override
  Stream<ResultsSnapshot> watchResults(String eventId) =>
      Stream.error(const RepositoryException(_message));
}

class UnavailableAnalyticsRepository implements AnalyticsRepository {
  const UnavailableAnalyticsRepository();

  @override
  Future<void> requestExport(String eventId) =>
      Future.error(const RepositoryException(_message));

  @override
  Future<EventAnalytics> summary(String eventId) =>
      Future.error(const RepositoryException(_message));
}

class UnavailableActivityRepository implements ActivityRepository {
  const UnavailableActivityRepository();

  @override
  Future<void> markAllRead() =>
      Future.error(const RepositoryException(_message));

  @override
  Stream<List<ActivityItem>> watchActivity() =>
      Stream.error(const RepositoryException(_message));
}

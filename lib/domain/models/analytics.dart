import 'package:flutter/foundation.dart';

/// Aggregated, privacy-safe analytics. Never contains participant identity.
@immutable
class EventAnalytics {
  const EventAnalytics({
    required this.eventId,
    required this.acceptedBallots,
    required this.participationByHour,
    required this.verificationStarted,
    required this.verificationCompleted,
    required this.failedVerificationAttempts,
    required this.suspiciousIndicators,
    this.platformSplit = const {},
  });

  final String eventId;
  final int acceptedBallots;

  /// Ballot counts bucketed by hour, oldest first.
  final List<int> participationByHour;
  final int verificationStarted;
  final int verificationCompleted;
  final int failedVerificationAttempts;
  final List<String> suspiciousIndicators;

  /// e.g. {'iOS': 0.6, 'Android': 0.4}. Only shown when the sample is large
  /// enough to be privacy-safe (empty map = hidden).
  final Map<String, double> platformSplit;

  double get verificationCompletionRate =>
      verificationStarted == 0 ? 0 : verificationCompleted / verificationStarted;

  double get submissionRate =>
      verificationCompleted == 0 ? 0 : acceptedBallots / verificationCompleted;
}

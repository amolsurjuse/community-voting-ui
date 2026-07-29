import 'package:flutter/foundation.dart';

enum ActivityKind {
  eventPublished,
  eventOpened,
  closingSoon,
  eventClosed,
  resultsFinalized,
  verificationFailures,
  suspiciousActivity,
  exportReady,
}

@immutable
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.occurredAt,
    this.eventId,
    this.read = false,
  });

  final String id;
  final ActivityKind kind;
  final String title;
  final String body;
  final DateTime occurredAt;
  final String? eventId;
  final bool read;

  ActivityItem copyWith({bool? read}) => ActivityItem(
        id: id,
        kind: kind,
        title: title,
        body: body,
        occurredAt: occurredAt,
        eventId: eventId,
        read: read ?? this.read,
      );
}

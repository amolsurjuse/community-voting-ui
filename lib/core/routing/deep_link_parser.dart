import 'package:flutter/foundation.dart';

/// Typed representation of every supported inbound link.
///
/// Supported paths:
///   /e/{publicEventId}
///   /e/{publicEventId}/vote
///   /e/{publicEventId}/results
///   /invite/{invitationToken}
@immutable
sealed class DeepLink {
  const DeepLink();

  static DeepLink? tryParse(Uri uri) {
    final segments =
        uri.pathSegments.where((s) => s.isNotEmpty).toList(growable: false);
    if (segments.isEmpty) return null;

    if (segments.first == 'e' && segments.length >= 2) {
      final id = segments[1];
      if (!_isValidPublicId(id)) return const InvalidLink();
      if (segments.length == 2) return EventLink(id);
      return switch (segments[2]) {
        'vote' => EventVoteLink(id),
        'results' => EventResultsLink(id),
        _ => const InvalidLink(),
      };
    }
    if (segments.first == 'invite' && segments.length == 2) {
      final token = segments[1];
      if (token.length < 6) return const InvalidLink();
      return InviteLink(token);
    }
    return const InvalidLink();
  }

  static bool _isValidPublicId(String id) =>
      RegExp(r'^[a-zA-Z0-9_-]{4,24}$').hasMatch(id);
}

class EventLink extends DeepLink {
  const EventLink(this.publicId);
  final String publicId;
}

class EventVoteLink extends DeepLink {
  const EventVoteLink(this.publicId);
  final String publicId;
}

class EventResultsLink extends DeepLink {
  const EventResultsLink(this.publicId);
  final String publicId;
}

class InviteLink extends DeepLink {
  const InviteLink(this.token);
  final String token;
}

class InvalidLink extends DeepLink {
  const InvalidLink();
}

import 'package:flutter/foundation.dart';

import 'candidate.dart';
import 'enums.dart';

@immutable
class VotingRules {
  const VotingRules({
    required this.ballotType,
    this.minSelections = 1,
    this.maxSelections = 1,
    this.requireFullRanking = false,
    this.allowReview = true,
    this.allowChangeBeforeSubmit = true,
    this.rankedAlgorithm = 'Instant runoff (single transferable vote)',
    this.tieBreakPolicy =
        'Ties are broken by earliest-round support, then by random draw.',
  });

  final BallotType ballotType;
  final int minSelections;
  final int maxSelections;
  final bool requireFullRanking;
  final bool allowReview;
  final bool allowChangeBeforeSubmit;
  final String rankedAlgorithm;
  final String tieBreakPolicy;

  VotingRules copyWith({
    BallotType? ballotType,
    int? minSelections,
    int? maxSelections,
    bool? requireFullRanking,
    bool? allowReview,
    bool? allowChangeBeforeSubmit,
  }) {
    return VotingRules(
      ballotType: ballotType ?? this.ballotType,
      minSelections: minSelections ?? this.minSelections,
      maxSelections: maxSelections ?? this.maxSelections,
      requireFullRanking: requireFullRanking ?? this.requireFullRanking,
      allowReview: allowReview ?? this.allowReview,
      allowChangeBeforeSubmit:
          allowChangeBeforeSubmit ?? this.allowChangeBeforeSubmit,
      rankedAlgorithm: rankedAlgorithm,
      tieBreakPolicy: tieBreakPolicy,
    );
  }
}

@immutable
class VotingEvent {
  const VotingEvent({
    required this.id,
    required this.publicId,
    required this.title,
    required this.organizerName,
    required this.visibility,
    required this.rules,
    required this.verificationLevel,
    required this.resultVisibility,
    required this.status,
    required this.candidates,
    this.shortDescription = '',
    this.longDescription = '',
    this.category = EventCategory.community,
    this.coverSeed = 0,
    this.coverEmoji = '🗳️',
    this.location = '',
    this.language = 'English',
    this.organizerVerified = true,
    this.startsAt,
    this.endsAt,
    this.totalBallots = 0,
    this.minResultThreshold = 0,
    this.timeZone = 'Local time',
    this.createdAt,
  });

  final String id;

  /// Short shareable identifier used in /e/{publicId} links.
  final String publicId;
  final String title;
  final String shortDescription;
  final String longDescription;
  final EventCategory category;
  final int coverSeed;
  final String coverEmoji;
  final String location;
  final String language;
  final String organizerName;
  final bool organizerVerified;
  final EventVisibility visibility;
  final VotingRules rules;
  final VerificationLevel verificationLevel;
  final ResultVisibility resultVisibility;
  final EventStatus status;
  final List<Candidate> candidates;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int totalBallots;
  final int minResultThreshold;
  final String timeZone;
  final DateTime? createdAt;

  bool get isOpen => status == EventStatus.open;
  bool get isClosed =>
      status == EventStatus.closed || status == EventStatus.archived;
  bool get isDraft => status == EventStatus.draft;

  List<Candidate> get activeCandidates =>
      (candidates.where((c) => c.active).toList()
        ..sort((a, b) => a.order.compareTo(b.order)));

  /// Whether a participant who has voted ([hasVoted]) may see results now.
  bool canSeeResults({required bool hasVoted, bool isOrganizer = false}) {
    if (isOrganizer) return true;
    return switch (resultVisibility) {
      ResultVisibility.live => true,
      ResultVisibility.afterVote => hasVoted || isClosed,
      ResultVisibility.afterClose => isClosed,
      ResultVisibility.organizerOnly => false,
    };
  }

  VotingEvent copyWith({
    String? title,
    String? shortDescription,
    String? longDescription,
    EventCategory? category,
    int? coverSeed,
    String? coverEmoji,
    String? location,
    String? language,
    String? organizerName,
    EventVisibility? visibility,
    VotingRules? rules,
    VerificationLevel? verificationLevel,
    ResultVisibility? resultVisibility,
    EventStatus? status,
    List<Candidate>? candidates,
    DateTime? startsAt,
    bool clearStartsAt = false,
    DateTime? endsAt,
    bool clearEndsAt = false,
    int? totalBallots,
    int? minResultThreshold,
  }) {
    return VotingEvent(
      id: id,
      publicId: publicId,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      longDescription: longDescription ?? this.longDescription,
      category: category ?? this.category,
      coverSeed: coverSeed ?? this.coverSeed,
      coverEmoji: coverEmoji ?? this.coverEmoji,
      location: location ?? this.location,
      language: language ?? this.language,
      organizerName: organizerName ?? this.organizerName,
      organizerVerified: organizerVerified,
      visibility: visibility ?? this.visibility,
      rules: rules ?? this.rules,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      resultVisibility: resultVisibility ?? this.resultVisibility,
      status: status ?? this.status,
      candidates: candidates ?? this.candidates,
      startsAt: clearStartsAt ? null : (startsAt ?? this.startsAt),
      endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
      totalBallots: totalBallots ?? this.totalBallots,
      minResultThreshold: minResultThreshold ?? this.minResultThreshold,
      timeZone: timeZone,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) => other is VotingEvent && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

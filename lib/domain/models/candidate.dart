import 'package:flutter/foundation.dart';

/// A selectable item: person, product, idea, entry.
///
/// [organizerNotes] is private organizer data and must never be rendered in
/// participant-facing UI.
@immutable
class Candidate {
  const Candidate({
    required this.id,
    required this.name,
    this.subtitle = '',
    this.description = '',
    this.organization = '',
    this.organizerNotes = '',
    this.colorSeed = 0,
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String name;
  final String subtitle;
  final String description;
  final String organization;
  final String organizerNotes;

  /// Seed for the generated avatar gradient (keeps the app asset-free).
  final int colorSeed;
  final int order;
  final bool active;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Candidate copyWith({
    String? name,
    String? subtitle,
    String? description,
    String? organization,
    String? organizerNotes,
    int? colorSeed,
    int? order,
    bool? active,
  }) {
    return Candidate(
      id: id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      organization: organization ?? this.organization,
      organizerNotes: organizerNotes ?? this.organizerNotes,
      colorSeed: colorSeed ?? this.colorSeed,
      order: order ?? this.order,
      active: active ?? this.active,
    );
  }

  @override
  bool operator ==(Object other) => other is Candidate && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

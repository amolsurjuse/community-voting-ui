import 'package:flutter/foundation.dart';

@immutable
class Organizer {
  const Organizer({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.emailVerified = false,
    this.phoneVerified = false,
  });

  final String id;
  final String fullName;
  final String email;

  /// Masked for display; raw numbers stay server-side in a real backend.
  final String phone;
  final bool emailVerified;
  final bool phoneVerified;

  bool get fullyVerified => emailVerified && phoneVerified;

  Organizer copyWith({
    String? fullName,
    String? email,
    String? phone,
    bool? emailVerified,
    bool? phoneVerified,
  }) {
    return Organizer(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
    );
  }
}

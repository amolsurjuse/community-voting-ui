import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_store.dart';
import '../../data/providers.dart';
import '../../domain/models/organizer.dart';
import '../../domain/repositories.dart';

enum SessionPhase { initializing, initFailed, unauthenticated, authenticated }

@immutable
class SessionState {
  const SessionState({required this.phase, this.organizer, this.error});

  final SessionPhase phase;
  final Organizer? organizer;
  final String? error;

  bool get isAuthenticated =>
      phase == SessionPhase.authenticated && organizer != null;
}

/// App initialization + authentication lifecycle.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    return const SessionState(phase: SessionPhase.initializing);
  }

  AuthRepository get _auth => ref.read(authRepositoryProvider);
  SecureStore get _store => ref.read(secureStoreProvider);

  /// Secure installation initialization + session restoration.
  Future<void> initialize() async {
    state = const SessionState(phase: SessionPhase.initializing);
    try {
      final existing = await _store.read(SecureKey.installationId);
      if (existing == null) {
        await _store.write(
          SecureKey.installationId,
          'inst_${DateTime.now().microsecondsSinceEpoch}',
        );
        await _store.write(SecureKey.installationKeyAlias, 'pv_install_key_v1');
      }
      final organizer = await _auth.restoreSession();
      state = organizer == null
          ? const SessionState(phase: SessionPhase.unauthenticated)
          : SessionState(
              phase: SessionPhase.authenticated, organizer: organizer);
    } catch (_) {
      state = const SessionState(
        phase: SessionPhase.initFailed,
        error:
            'We could not finish setting up the app. Check your connection and retry.',
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final organizer = await _auth.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
    );
    state =
        SessionState(phase: SessionPhase.authenticated, organizer: organizer);
  }

  Future<void> verifyEmail(String code) async {
    final organizer = await _auth.verifyEmail(code);
    state =
        SessionState(phase: SessionPhase.authenticated, organizer: organizer);
  }

  Future<void> resendEmailCode() => _auth.resendEmailCode();

  Future<void> sendPhoneOtp(String phone) => _auth.sendPhoneOtp(phone);

  Future<void> verifyPhoneOtp(String code) async {
    final organizer = await _auth.verifyPhoneOtp(code);
    state =
        SessionState(phase: SessionPhase.authenticated, organizer: organizer);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const SessionState(phase: SessionPhase.unauthenticated);
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

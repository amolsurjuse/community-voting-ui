/// Abstraction over platform secure storage (Keychain / Keystore).
///
/// The app never persists raw phone numbers, ballot selections or participant
/// identity through this interface — only opaque credentials:
/// installation identifier, installation key alias, organizer auth tokens and
/// short-lived verification-session tokens.
abstract class SecureStore {
  Future<String?> read(SecureKey key);
  Future<void> write(SecureKey key, String value);
  Future<void> delete(SecureKey key);
  Future<void> clear();
}

enum SecureKey {
  installationId,
  installationKeyAlias,
  organizerAuthToken,
  organizerRefreshToken,
  authDeviceId,
  organizerProfile,
  verificationSessionToken,
}

/// In-memory implementation used for development and tests.
/// Swap with a `flutter_secure_storage` backed implementation for production.
class InMemorySecureStore implements SecureStore {
  final Map<SecureKey, String> _values = {};

  @override
  Future<String?> read(SecureKey key) async => _values[key];

  @override
  Future<void> write(SecureKey key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(SecureKey key) async {
    _values.remove(key);
  }

  @override
  Future<void> clear() async => _values.clear();
}

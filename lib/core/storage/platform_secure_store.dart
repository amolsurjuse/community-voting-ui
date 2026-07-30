import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_store.dart';

class PlatformSecureStore implements SecureStore {
  const PlatformSecureStore(this._storage);

  final FlutterSecureStorage _storage;

  static const storage = FlutterSecureStorage();

  @override
  Future<String?> read(SecureKey key) => _storage.read(key: key.name);

  @override
  Future<void> write(SecureKey key, String value) =>
      _storage.write(key: key.name, value: value);

  @override
  Future<void> delete(SecureKey key) => _storage.delete(key: key.name);

  @override
  Future<void> clear() => _storage.deleteAll();
}

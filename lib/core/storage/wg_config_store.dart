import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists WireGuard `wg-quick` config text per signed-in user (Android Keystore / platform equivalents).
abstract class WgConfigStore {
  Future<String?> read(String userId);
  Future<void> write(String userId, String config);
  Future<void> delete(String userId);
}

class SecureWgConfigStore implements WgConfigStore {
  SecureWgConfigStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String _key(String userId) => 'mira_vpn_wg_config_$userId';

  @override
  Future<String?> read(String userId) => _storage.read(key: _key(userId));

  @override
  Future<void> write(String userId, String config) =>
      _storage.write(key: _key(userId), value: config);

  @override
  Future<void> delete(String userId) => _storage.delete(key: _key(userId));
}

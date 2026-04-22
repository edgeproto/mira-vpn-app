import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class GuestDeviceStore {
  Future<String> readOrCreateDeviceId();
}

class SecureGuestDeviceStore implements GuestDeviceStore {
  SecureGuestDeviceStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'mira_vpn_guest_device_id';

  @override
  Future<String> readOrCreateDeviceId() async {
    final existing = await _storage.read(key: _key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated = _generateId();
    await _storage.write(key: _key, value: generated);
    return generated;
  }

  String _generateId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

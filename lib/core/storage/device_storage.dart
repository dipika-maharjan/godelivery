import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'token_storage.dart';

final deviceStorageProvider = Provider<DeviceStorage>((ref) {
  return DeviceStorage(ref.watch(secureStorageProvider));
});

/// Persists the app's stable per-install identifier and the backend's
/// device record id, so re-registering on every launch isn't needed.
class DeviceStorage {
  DeviceStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _deviceIdentifierKey = 'godelivery.deviceIdentifier';
  static const _registeredDeviceIdKey = 'godelivery.registeredDeviceId';

  Future<String> getOrCreateDeviceIdentifier() async {
    final existing = await _storage.read(key: _deviceIdentifierKey);
    if (existing != null) return existing;
    final generated = const Uuid().v4();
    await _storage.write(key: _deviceIdentifierKey, value: generated);
    return generated;
  }

  Future<String?> readRegisteredDeviceId() async {
    return _storage.read(key: _registeredDeviceIdKey);
  }

  Future<void> saveRegisteredDeviceId(String id) async {
    await _storage.write(key: _registeredDeviceIdKey, value: id);
  }
}

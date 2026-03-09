import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

abstract class InstallationIdServiceBase {
  Future<String> getInstallationId();
}

class InstallationIdService implements InstallationIdServiceBase {
  InstallationIdService({FlutterSecureStorage? storage, Uuid? uuid})
    : _storage = storage ?? const FlutterSecureStorage(),
      _uuid = uuid ?? const Uuid();

  static const String _storageKey = 'app_installation_id';

  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  @override
  Future<String> getInstallationId() async {
    final existingId = await _storage.read(key: _storageKey);
    if (existingId != null && existingId.trim().isNotEmpty) {
      return existingId;
    }

    final installationId = _uuid.v4();
    await _storage.write(key: _storageKey, value: installationId);
    return installationId;
  }
}

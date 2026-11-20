import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The student's own Gemini key, kept only in the platform's secure storage
/// (Keychain on iOS, Keystore-backed on Android). It never leaves the phone
/// except in calls to Google.
class KeyStore {
  KeyStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const _keyName = 'gemini_api_key';
  static const _modelName = 'gemini_model';
  final FlutterSecureStorage _storage;

  Future<String?> readKey() => _storage.read(key: _keyName);
  Future<void> saveKey(String key) => _storage.write(key: _keyName, value: key.trim());
  Future<void> clearKey() => _storage.delete(key: _keyName);

  Future<String?> readModel() => _storage.read(key: _modelName);
  Future<void> saveModel(String model) => _storage.write(key: _modelName, value: model.trim());
}

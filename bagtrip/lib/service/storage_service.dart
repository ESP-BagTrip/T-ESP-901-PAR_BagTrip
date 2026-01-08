import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // Token management
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // User data management (optional, for caching)
  Future<void> saveUser(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  Future<String?> getUser() async {
    return await _storage.read(key: _userKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

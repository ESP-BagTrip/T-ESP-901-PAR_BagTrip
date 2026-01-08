import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bagtrip/model/user.dart';
import 'dart:io';

class AuthService {
  // 10.0.2.2 for android emulator, localhost for apple simulator
  // For physical device, use your machine's LAN IP (e.g. 192.168.1.164)
  static final String baseUrl = Platform.isAndroid 
      ? 'http://192.168.1.164:3000/auth' 
      : 'http://localhost:3000/auth';

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService() {
    _dio.options.validateStatus = (status) {
      return status! < 500;
    };
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> _persistToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> _deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<User?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _persistToken(data['token']);
        return User.fromJson(data['user']);
      } else {
        throw Exception(response.data['detail'] ?? 'Login failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signup(String email, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/signup',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 201) {
        final data = response.data;
        await _persistToken(data['token']);
        return User.fromJson(data['user']);
      } else {
        throw Exception(response.data['detail'] ?? 'Signup failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> me() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _dio.get(
        '$baseUrl/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      } else {
        await _deleteToken(); // Invalid token
        return null;
      }
    } catch (e) {
      await _deleteToken();
      return null;
    }
  }

  Future<void> logout() async {
    await _deleteToken();
  }
}

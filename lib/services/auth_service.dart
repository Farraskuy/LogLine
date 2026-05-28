import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';

import 'local_storage_service.dart';

class AuthService {
  AuthService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuthentication,
    LocalStorageService? localStorageService,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _localAuthentication = localAuthentication ?? LocalAuthentication(),
       _localStorageService = localStorageService ?? LocalStorageService();

  static const _sessionKey = 'logline_session_token';
  static const _localUserKey = 'logline_local_user';
  static const _uuid = Uuid();

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuthentication;
  final LocalStorageService _localStorageService;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final userId = _userIdFromEmail(normalizedEmail);
    final user = {
      'id': userId,
      'name': name.trim().isEmpty ? 'Pengguna LogLine' : name.trim(),
      'email': normalizedEmail,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _localStorageService.users.put(userId, user);
    await _secureStorage.write(
      key: _passwordKey(userId),
      value: _encodePassword(password),
    );
    await saveLocalSession(userId: userId, sessionToken: _uuid.v4());
  }

  Future<void> login({required String email, required String password}) async {
    final userId = _userIdFromEmail(email.trim().toLowerCase());
    final savedPassword = await _secureStorage.read(key: _passwordKey(userId));
    if (savedPassword != _encodePassword(password)) {
      throw AuthException('Email atau password belum sesuai.');
    }
    await saveLocalSession(userId: userId, sessionToken: _uuid.v4());
  }

  Future<Map<String, dynamic>?> currentUser() async {
    final id = await currentUserId();
    if (id == null) return null;
    final user = _localStorageService.users.get(id);
    return user == null ? null : Map<String, dynamic>.from(user);
  }

  Future<void> saveLocalSession({
    required String userId,
    required String sessionToken,
  }) async {
    await _secureStorage.write(key: _localUserKey, value: userId);
    await _secureStorage.write(key: _sessionKey, value: sessionToken);
  }

  Future<String?> currentUserId() {
    return _secureStorage.read(key: _localUserKey);
  }

  Future<String?> sessionToken() {
    return _secureStorage.read(key: _sessionKey);
  }

  Future<bool> authenticateWithBiometric({
    String reason = 'Authenticate to open LogLine',
  }) async {
    final canCheck = await _localAuthentication.canCheckBiometrics;
    final supported = await _localAuthentication.isDeviceSupported();
    if (!canCheck && !supported) return false;

    return _localAuthentication.authenticate(
      localizedReason: reason,
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
  }

  Future<void> signOut() async {
    await _secureStorage.delete(key: _sessionKey);
    await _secureStorage.delete(key: _localUserKey);
  }

  String _userIdFromEmail(String email) {
    return base64Url.encode(utf8.encode(email)).replaceAll('=', '');
  }

  String _passwordKey(String userId) => 'logline_password_$userId';

  String _encodePassword(String password) {
    return base64Url.encode(utf8.encode(password));
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

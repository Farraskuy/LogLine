import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  AuthService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuthentication,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _localAuthentication = localAuthentication ?? LocalAuthentication();

  static const _sessionKey = 'logline_session_token';
  static const _localUserKey = 'logline_local_user';

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuthentication;

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
}

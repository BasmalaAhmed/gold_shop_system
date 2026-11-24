import 'dart:convert';

import 'package:gold_shop_app/modules/auth_notification/core/security/secure_storage_service.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/entities/session.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/repos/session_repo.dart';

class SessionRepoImpl implements SessionRepo {
  final SecureStorageService secureStorageService;

  SessionRepoImpl(this.secureStorageService);

  static const String _sessionKey = 'user_session';

  @override
  Future<void> saveSession(Session session) async {
    final sessionData = {
      'access_token': session.accessToken,
      'refresh_token': session.refreshToken,
      'expires_at': session.expiresAt.toIso8601String(),
    };

    await secureStorageService.write(
      key: _sessionKey,
      value: jsonEncode(sessionData),
    );
  }

  @override
  Future<Session?> getSession() async {
    final storedData = await secureStorageService.read(key: _sessionKey);

    if (storedData == null) return null;

    try {
      final sessionData = jsonDecode(storedData) as Map<String, dynamic>;

      return Session(
        accessToken: sessionData['access_token'] as String,
        refreshToken: sessionData['refresh_token'] as String,
        expiresAt: DateTime.parse(sessionData['expires_at'] as String),
      );
    } on FormatException {
      await clearSession();
      return null;
    } on TypeError {
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    await secureStorageService.delete(key: _sessionKey);
  }
}

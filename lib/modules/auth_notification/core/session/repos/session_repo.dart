import 'package:gold_shop_app/modules/auth_notification/core/session/entities/session.dart';

abstract class SessionRepo {
  Future<void> saveSession(Session session);

  Future<Session?> getSession();

  Future<void> clearSession();
}
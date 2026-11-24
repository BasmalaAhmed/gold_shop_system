import 'package:gold_shop_app/modules/auth_notification/core/session/entities/session.dart';

abstract class SessionRefreshRepo {
  Future<Session> refreshSession({
    required String refreshToken,
  });
}
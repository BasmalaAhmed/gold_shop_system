import 'package:gold_shop_app/modules/auth_notification/core/session/data/datasources/mock_session_api.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/entities/session.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/repos/session_refresh_repo.dart';

class SessionRefreshRepoImpl
    implements SessionRefreshRepo {
  final MockSessionApi mockSessionApi;

  SessionRefreshRepoImpl(this.mockSessionApi);

  @override
  Future<Session> refreshSession({
    required String refreshToken,
  }) async {
    final response = await mockSessionApi.refreshToken(
      refreshToken: refreshToken,
    );

    return Session(
      accessToken: response['access_token'] as String,
      refreshToken: response['refresh_token'] as String,
      expiresAt: DateTime.parse(
        response['expires_at'] as String,
      ),
    );
  }
}
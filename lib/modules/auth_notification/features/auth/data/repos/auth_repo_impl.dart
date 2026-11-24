import 'package:gold_shop_app/modules/auth_notification/features/auth/data/datasources/mock_auth_api.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/auth_result.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/device_verification_challenge.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/login_credentials.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/otp_challenge.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/repos/auth_repo.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/entities/session.dart';

class AuthRepoImpl implements AuthRepo {
  final MockAuthApi mockAuthApi;

  AuthRepoImpl(this.mockAuthApi);

  @override
  Future<OtpChallenge> login(LoginCredentials credentials) async {
    final response = await mockAuthApi.login(
      email: credentials.email,
      password: credentials.password,
    );

    return OtpChallenge(
      challengeId: response['challenge_id'] as String,
      maskedDestination: response['masked_destination'] as String,
    );
  }

  @override
  Future<AuthResult> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    final response = await mockAuthApi.verifyOtp(
      challengeId: challengeId,
      code: code,
    );

    final status = response['status'];

    if (status == 'device_verification_required') {
      return DeviceVerificationRequired(
        challenge: DeviceVerificationChallenge(
          challengeId: response['challenge_id'] as String,
          deviceName: response['device_name'] as String,
        ),
      );
    } else if (status == 'success') {
      return AuthSuccess(
        session: Session(
          accessToken: response['access_token'] as String,
          refreshToken: response['refresh_token'] as String,
          expiresAt: DateTime.parse(response['expires_at'] as String),
        ),
      );
    }

    throw FormatException('Unknown authentication status: $status');
  }

  @override
  Future<AuthResult> verifyDevice({
    required String challengeId,
    required String code,
  }) async {
    final response = await mockAuthApi.verifyDevice(
      challengeId: challengeId,
      code: code,
    );

    final session = Session(
      accessToken: response['access_token'] as String,
      refreshToken: response['refresh_token'] as String,
      expiresAt: DateTime.parse(response['expires_at'] as String),
    );

    return AuthSuccess(session: session);
  }
}

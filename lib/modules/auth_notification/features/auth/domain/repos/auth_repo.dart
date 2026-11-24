import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/auth_result.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/login_credentials.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/otp_challenge.dart';

abstract class AuthRepo {
  Future<OtpChallenge> login(LoginCredentials credentials);

  Future<AuthResult> verifyOtp({
  required String challengeId,
  required String code,
});

Future<AuthResult> verifyDevice({
  required String challengeId,
  required String code,
});
}

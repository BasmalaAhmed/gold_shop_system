import 'package:gold_shop_app/modules/auth_notification/core/session/entities/session.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/device_verification_challenge.dart';

sealed class AuthResult {
  const AuthResult();
}

class DeviceVerificationRequired extends AuthResult {
  final DeviceVerificationChallenge challenge;

  const DeviceVerificationRequired({required this.challenge});
}

class AuthSuccess extends AuthResult {
  final Session session;

  const AuthSuccess({required this.session});
}

import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/login_credentials.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/otp_challenge.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/repos/auth_repo.dart';

class LoginUseCase {
  final AuthRepo repo;

  const LoginUseCase(this.repo);

  Future<OtpChallenge> call(LoginCredentials credentials) {
    return repo.login(credentials);
  }
}

import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/auth_result.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/repos/auth_repo.dart';

class VerifyOtpUseCase {
  final AuthRepo repo;

  const VerifyOtpUseCase(this.repo);

  Future<AuthResult> call({required String challengeId, required String code}) {
    return repo.verifyOtp(challengeId: challengeId, code: code);
  }
}

import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/device_verification_challenge.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/otp_challenge.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthOtpRequired extends AuthState {
  final OtpChallenge challenge;
  final String? errorMessage;

  const AuthOtpRequired(
    this.challenge, {
    this.errorMessage,
  });
}

class AuthDeviceVerificationRequired extends AuthState {
  final DeviceVerificationChallenge challenge;
  final String? errorMessage;

  const AuthDeviceVerificationRequired(
    this.challenge, {
    this.errorMessage,
  });
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);
}
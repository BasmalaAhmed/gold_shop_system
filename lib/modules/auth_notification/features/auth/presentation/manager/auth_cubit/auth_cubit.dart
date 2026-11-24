import 'dart:async';

import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/device_verification_challenge.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/otp_challenge.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/session_manager.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/auth_result.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/login_credentials.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/usecases/login_usecase.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/usecases/verify_device_usecase.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final VerifyDeviceUseCase verifyDeviceUseCase;
  final SessionManager sessionManager;
  OtpChallenge? _otpChallenge;
  DeviceVerificationChallenge? _deviceChallenge;
  bool _isProcessing = false;
  late final StreamSubscription<void> _refreshFailureSubscription;

  AuthCubit({
    required this.loginUseCase,
    required this.verifyOtpUseCase,
    required this.verifyDeviceUseCase,
    required this.sessionManager,
  }) : super(const AuthInitial()) {
    _refreshFailureSubscription = sessionManager.onRefreshFailure.listen((_) {
      if (isClosed) return;

      _otpChallenge = null;
      _deviceChallenge = null;

      emit(const AuthUnauthenticated());
    });
  }

  @override
  Future<void> close() async {
    await _refreshFailureSubscription.cancel();
    await super.close();
  }

  Future<void> restoreSession() async {
    if (_isProcessing) return;

    _isProcessing = true;

    emit(const AuthLoading());

    try {
      final session = sessionManager.currentSession;

      if (session == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      if (session.isExpired) {
        await sessionManager.refreshSession();
      }

      if (isClosed || state is AuthUnauthenticated) return;

      emit(const AuthAuthenticated());
    } catch (_) {
      if (!isClosed) {
        emit(const AuthUnauthenticated());
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> login(LoginCredentials credentials) async {
    if (_isProcessing) return;

    _isProcessing = true;

    _otpChallenge = null;
    _deviceChallenge = null;

    emit(const AuthLoading());

    try {
      final challenge = await loginUseCase(credentials);
      if (isClosed) return;
      _otpChallenge = challenge;
      emit(AuthOtpRequired(challenge));
    } catch (_) {
      if (!isClosed) {
        emit(const AuthFailure('فشل تسجيل الدخول.'));
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> verifyOtp(String code) async {
    if (_isProcessing) return;

    final challenge = _otpChallenge;

    if (challenge == null) {
      emit(const AuthFailure('لم يتم العثور على رمز التحقق (OTP).'));
      return;
    }

    _isProcessing = true;

    emit(const AuthLoading());

    try {
      AuthResult result;

      try {
        result = await verifyOtpUseCase(
          challengeId: challenge.challengeId,
          code: code,
        );
      } catch (_) {
        if (!isClosed && _otpChallenge == challenge) {
          emit(
            AuthOtpRequired(
              challenge,
              errorMessage: 'فشل التحقق من رمز التحقق (OTP).',
            ),
          );
        }
        return;
      }

      if (isClosed) return;

      if (result is DeviceVerificationRequired) {
        _deviceChallenge = result.challenge;
        _otpChallenge = null;

        emit(AuthDeviceVerificationRequired(result.challenge));
      } else if (result is AuthSuccess) {
        try {
          await _completeAuthentication(result);
        } catch (_) {
          if (!isClosed) {
            emit(const AuthFailure('فشل حفظ الجلسة.'));
          }
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> verifyDevice(String code) async {
    if (_isProcessing) return;

    final challenge = _deviceChallenge;

    if (challenge == null) {
      emit(const AuthFailure('لم يتم العثور على الجهاز.'));
      return;
    }

    _isProcessing = true;

    emit(const AuthLoading());

    try {
      AuthResult result;

      try {
        result = await verifyDeviceUseCase(
          challengeId: challenge.challengeId,
          code: code,
        );
      } catch (_) {
        if (!isClosed && _deviceChallenge == challenge) {
          emit(
            AuthDeviceVerificationRequired(
              challenge,
              errorMessage: 'فشل التحقق من الجهاز.',
            ),
          );
        }
        return;
      }

      if (isClosed) return;

      if (result is AuthSuccess) {
        try {
          await _completeAuthentication(result);
        } catch (_) {
          if (!isClosed) {
            emit(const AuthFailure('فشل حفظ الجلسة.'));
          }
        }
      } else if (result is DeviceVerificationRequired) {
        _deviceChallenge = result.challenge;

        emit(AuthDeviceVerificationRequired(result.challenge));
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _completeAuthentication(AuthSuccess result) async {
    await sessionManager.setSession(result.session);

    if (isClosed) return;

    _otpChallenge = null;
    _deviceChallenge = null;

    emit(const AuthAuthenticated());
  }

  Future<void> logout() async {
    _isProcessing = false;
    emit(const AuthLoading());

    try {
      await sessionManager.logout();
      _otpChallenge = null;
      _deviceChallenge = null;
      if (!isClosed) emit(const AuthUnauthenticated());
    } catch (_) {
      if (!isClosed) {
        emit(const AuthFailure('فشل تسجيل الخروج. يرجى المحاولة مجدداً.'));
      }
    }
  }
}

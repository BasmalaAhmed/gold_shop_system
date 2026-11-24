import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/entities/session.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/session_manager.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/auth_result.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/device_verification_challenge.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/login_credentials.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/otp_challenge.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/usecases/login_usecase.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/usecases/verify_device_usecase.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockVerifyOtpUseCase extends Mock implements VerifyOtpUseCase {}

class MockVerifyDeviceUseCase extends Mock implements VerifyDeviceUseCase {}

class MockSessionManager extends Mock implements SessionManager {}

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockVerifyOtpUseCase mockVerifyOtpUseCase;
  late MockVerifyDeviceUseCase mockVerifyDeviceUseCase;
  late MockSessionManager mockSessionManager;
  late StreamController<void> refreshFailureController;
  late AuthCubit authCubit;

  final credentials = const LoginCredentials(
    email: 'user@example.com',
    password: 'Password123!',
  );

  final otpChallenge = const OtpChallenge(
    challengeId: 'challenge_001',
    maskedDestination: 'u***@example.com',
  );

  final deviceChallenge = const DeviceVerificationChallenge(
    challengeId: 'device_001',
    deviceName: 'Windows Desktop',
  );

  final session = Session(
    accessToken: 'mock_access_token_001',
    refreshToken: 'mock_refresh_token_001',
    expiresAt: DateTime.now().add(const Duration(minutes: 15)),
  );

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockVerifyOtpUseCase = MockVerifyOtpUseCase();
    mockVerifyDeviceUseCase = MockVerifyDeviceUseCase();
    mockSessionManager = MockSessionManager();
    refreshFailureController = StreamController<void>.broadcast();
    when(
      () => mockSessionManager.onRefreshFailure,
    ).thenAnswer((_) => refreshFailureController.stream);
    authCubit = AuthCubit(
      loginUseCase: mockLoginUseCase,
      verifyOtpUseCase: mockVerifyOtpUseCase,
      verifyDeviceUseCase: mockVerifyDeviceUseCase,
      sessionManager: mockSessionManager,
    );
  });

  tearDown(() async {
    await authCubit.close();
    await refreshFailureController.close();
  });

  test('restores unauthenticated state when no session exists', () async {
    when(() => mockSessionManager.currentSession).thenReturn(null);

    await authCubit.restoreSession();

    expect(authCubit.state, isA<AuthUnauthenticated>());

    verifyNever(() => mockSessionManager.refreshSession());
  });

  test('restores authenticated state with a valid session', () async {
    when(() => mockSessionManager.currentSession).thenReturn(session);

    await authCubit.restoreSession();

    expect(authCubit.state, isA<AuthAuthenticated>());

    verifyNever(() => mockSessionManager.refreshSession());
  });

  test('refreshes expired session before authentication', () async {
    final expiredSession = Session(
      accessToken: 'expired_access_token',
      refreshToken: 'mock_refresh_token_001',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    when(() => mockSessionManager.currentSession).thenReturn(expiredSession);

    when(
      () => mockSessionManager.refreshSession(),
    ).thenAnswer((_) async => session);

    await authCubit.restoreSession();

    expect(authCubit.state, isA<AuthAuthenticated>());

    verify(() => mockSessionManager.refreshSession()).called(1);
  });

  test('restores unauthenticated state when refresh fails', () async {
    final expiredSession = Session(
      accessToken: 'expired_access_token',
      refreshToken: 'invalid_refresh_token',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    when(() => mockSessionManager.currentSession).thenReturn(expiredSession);

    when(
      () => mockSessionManager.refreshSession(),
    ).thenThrow(Exception('Refresh failed'));

    await authCubit.restoreSession();

    expect(authCubit.state, isA<AuthUnauthenticated>());

    verify(() => mockSessionManager.refreshSession()).called(1);
  });

  test('starts with initial state', () {
    expect(authCubit.state, isA<AuthInitial>());
  });

  test('login emits loading then otpRequired', () async {
    when(
      () => mockLoginUseCase(credentials),
    ).thenAnswer((_) async => otpChallenge);

    final states = <AuthState>[];
    final subscription = authCubit.stream.listen(states.add);

    await authCubit.login(credentials);

    await pumpEventQueue();

    expect(states.map((state) => state.runtimeType).toList(), [
      AuthLoading,
      AuthOtpRequired,
    ]);

    expect(authCubit.state, isA<AuthOtpRequired>());

    final currentState = authCubit.state as AuthOtpRequired;

    expect(currentState.challenge, otpChallenge);

    verify(() => mockLoginUseCase(credentials)).called(1);

    await subscription.cancel();
  });

  test('login emits failure when login fails', () async {
    when(
      () => mockLoginUseCase(credentials),
    ).thenThrow(Exception('Invalid credentials'));

    await authCubit.login(credentials);

    expect(authCubit.state, isA<AuthFailure>());
  });

  test(
    'retries OTP verification using the same challenge after failure',
    () async {
      var attempts = 0;

      when(
        () => mockLoginUseCase(credentials),
      ).thenAnswer((_) async => otpChallenge);

      when(
        () =>
            mockVerifyOtpUseCase(challengeId: 'challenge_001', code: '123456'),
      ).thenAnswer((_) async {
        attempts++;

        if (attempts == 1) {
          throw Exception('Invalid OTP');
        }

        return AuthSuccess(session: session);
      });

      when(
        () => mockSessionManager.setSession(session),
      ).thenAnswer((_) async {});

      await authCubit.login(credentials);

      await authCubit.verifyOtp('123456');

      expect(authCubit.state, isA<AuthOtpRequired>());

      final state = authCubit.state as AuthOtpRequired;

      expect(state.challenge, otpChallenge);
      expect(state.errorMessage, 'فشل التحقق من رمز التحقق (OTP).');

      await authCubit.verifyOtp('123456');

      expect(authCubit.state, isA<AuthAuthenticated>());

      expect(attempts, 2);

      verify(
        () =>
            mockVerifyOtpUseCase(challengeId: 'challenge_001', code: '123456'),
      ).called(2);

      verify(() => mockSessionManager.setSession(session)).called(1);
    },
  );

  test('OTP verification requires device verification', () async {
    when(
      () => mockLoginUseCase(credentials),
    ).thenAnswer((_) async => otpChallenge);

    when(
      () => mockVerifyOtpUseCase(challengeId: 'challenge_001', code: '123456'),
    ).thenAnswer(
      (_) async => DeviceVerificationRequired(challenge: deviceChallenge),
    );

    await authCubit.login(credentials);

    await authCubit.verifyOtp('123456');

    expect(authCubit.state, isA<AuthDeviceVerificationRequired>());

    final currentState = authCubit.state as AuthDeviceVerificationRequired;

    expect(currentState.challenge, deviceChallenge);

    verify(
      () => mockVerifyOtpUseCase(challengeId: 'challenge_001', code: '123456'),
    ).called(1);
  });

  test('device verification saves session before authentication', () async {
    when(
      () => mockLoginUseCase(credentials),
    ).thenAnswer((_) async => otpChallenge);

    when(
      () => mockVerifyOtpUseCase(challengeId: 'challenge_001', code: '123456'),
    ).thenAnswer(
      (_) async => DeviceVerificationRequired(challenge: deviceChallenge),
    );

    when(
      () => mockVerifyDeviceUseCase(challengeId: 'device_001', code: '654321'),
    ).thenAnswer((_) async => AuthSuccess(session: session));

    when(() => mockSessionManager.setSession(session)).thenAnswer((_) async {});

    final states = <AuthState>[];
    final subscription = authCubit.stream.listen(states.add);

    await authCubit.login(credentials);
    await authCubit.verifyOtp('123456');
    await authCubit.verifyDevice('654321');

    await pumpEventQueue();

    expect(states.map((state) => state.runtimeType).toList(), [
      AuthLoading,
      AuthOtpRequired,
      AuthLoading,
      AuthDeviceVerificationRequired,
      AuthLoading,
      AuthAuthenticated,
    ]);

    expect(authCubit.state, isA<AuthAuthenticated>());

    verify(() => mockSessionManager.setSession(session)).called(1);

    await subscription.cancel();
  });

  test('does not authenticate when saving session fails', () async {
    when(
      () => mockLoginUseCase(credentials),
    ).thenAnswer((_) async => otpChallenge);

    when(
      () => mockVerifyOtpUseCase(challengeId: 'challenge_001', code: '123456'),
    ).thenAnswer(
      (_) async => DeviceVerificationRequired(challenge: deviceChallenge),
    );

    when(
      () => mockVerifyDeviceUseCase(challengeId: 'device_001', code: '654321'),
    ).thenAnswer((_) async => AuthSuccess(session: session));

    when(
      () => mockSessionManager.setSession(session),
    ).thenThrow(Exception('Storage failed'));

    await authCubit.login(credentials);
    await authCubit.verifyOtp('123456');
    await authCubit.verifyDevice('654321');

    expect(authCubit.state, isA<AuthFailure>());

    verify(() => mockSessionManager.setSession(session)).called(1);
  });

  test(
    'retries device verification using the same challenge after failure',
    () async {
      var attempts = 0;

      when(
        () => mockLoginUseCase(credentials),
      ).thenAnswer((_) async => otpChallenge);

      when(
        () =>
            mockVerifyOtpUseCase(challengeId: 'challenge_001', code: '123456'),
      ).thenAnswer(
        (_) async => DeviceVerificationRequired(challenge: deviceChallenge),
      );

      when(
        () =>
            mockVerifyDeviceUseCase(challengeId: 'device_001', code: '654321'),
      ).thenAnswer((_) async {
        attempts++;

        if (attempts == 1) {
          throw Exception('Invalid device verification code');
        }

        return AuthSuccess(session: session);
      });

      when(
        () => mockSessionManager.setSession(session),
      ).thenAnswer((_) async {});

      await authCubit.login(credentials);
      await authCubit.verifyOtp('123456');

      await authCubit.verifyDevice('654321');

      expect(authCubit.state, isA<AuthDeviceVerificationRequired>());

      final state = authCubit.state as AuthDeviceVerificationRequired;

      expect(state.challenge, deviceChallenge);
      expect(state.errorMessage, 'فشل التحقق من الجهاز.');

      await authCubit.verifyDevice('654321');

      expect(authCubit.state, isA<AuthAuthenticated>());

      expect(attempts, 2);

      verify(
        () =>
            mockVerifyDeviceUseCase(challengeId: 'device_001', code: '654321'),
      ).called(2);

      verify(() => mockSessionManager.setSession(session)).called(1);
    },
  );

  test('does not emit state when cubit closes during login', () async {
    final completer = Completer<OtpChallenge>();

    when(
      () => mockLoginUseCase(credentials),
    ).thenAnswer((_) => completer.future);

    final loginFuture = authCubit.login(credentials);

    await authCubit.close();

    completer.complete(otpChallenge);

    await expectLater(loginFuture, completes);

    expect(authCubit.isClosed, isTrue);
  });

  test(
    'allows successful device verification after old refresh failure',
    () async {
      final completer = Completer<AuthResult>();

      when(
        () => mockLoginUseCase(credentials),
      ).thenAnswer((_) async => otpChallenge);

      when(
        () =>
            mockVerifyOtpUseCase(challengeId: 'challenge_001', code: '123456'),
      ).thenAnswer(
        (_) async => DeviceVerificationRequired(challenge: deviceChallenge),
      );

      when(
        () =>
            mockVerifyDeviceUseCase(challengeId: 'device_001', code: '654321'),
      ).thenAnswer((_) => completer.future);

      when(
        () => mockSessionManager.setSession(session),
      ).thenAnswer((_) async {});

      await authCubit.login(credentials);
      await authCubit.verifyOtp('123456');

      final verificationFuture = authCubit.verifyDevice('654321');

      refreshFailureController.add(null);

      await pumpEventQueue();

      expect(authCubit.state, isA<AuthUnauthenticated>());

      completer.complete(AuthSuccess(session: session));

      await verificationFuture;

      expect(authCubit.state, isA<AuthAuthenticated>());

      verify(() => mockSessionManager.setSession(session)).called(1);
    },
  );

  test(
    'does not restore device verification state after refresh failure',
    () async {
      final completer = Completer<AuthResult>();

      when(
        () => mockLoginUseCase(credentials),
      ).thenAnswer((_) async => otpChallenge);

      when(
        () =>
            mockVerifyOtpUseCase(challengeId: 'challenge_001', code: '123456'),
      ).thenAnswer(
        (_) async => DeviceVerificationRequired(challenge: deviceChallenge),
      );

      when(
        () =>
            mockVerifyDeviceUseCase(challengeId: 'device_001', code: '654321'),
      ).thenAnswer((_) => completer.future);

      await authCubit.login(credentials);
      await authCubit.verifyOtp('123456');

      final verificationFuture = authCubit.verifyDevice('654321');

      refreshFailureController.add(null);

      await pumpEventQueue();

      completer.completeError(Exception('Verification failed'));

      await verificationFuture;

      expect(authCubit.state, isA<AuthUnauthenticated>());

      verifyNever(() => mockSessionManager.setSession(session));
    },
  );

  test('does not restore OTP state after refresh failure', () async {
    final completer = Completer<AuthResult>();

    when(
      () => mockLoginUseCase(credentials),
    ).thenAnswer((_) async => otpChallenge);

    when(
      () => mockVerifyOtpUseCase(challengeId: 'challenge_001', code: '123456'),
    ).thenAnswer((_) => completer.future);

    await authCubit.login(credentials);

    final verificationFuture = authCubit.verifyOtp('123456');

    refreshFailureController.add(null);

    await pumpEventQueue();

    completer.completeError(Exception('OTP verification failed'));

    await verificationFuture;

    expect(authCubit.state, isA<AuthUnauthenticated>());
  });

  test(
    'does not restore authenticated state when user logs out while refresh is in-flight',
    () async {
      final expiredSession = Session(
        accessToken: 'expired_access_token',
        refreshToken: 'mock_refresh_token_001',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      final refreshCompleter = Completer<Session>();

      when(() => mockSessionManager.currentSession).thenReturn(expiredSession);

      when(
        () => mockSessionManager.refreshSession(),
      ).thenAnswer((_) => refreshCompleter.future);

      when(() => mockSessionManager.logout()).thenAnswer((_) async {});

      final restoreFuture = authCubit.restoreSession();

      expect(authCubit.state, isA<AuthLoading>());

      await authCubit.logout();

      expect(authCubit.state, isA<AuthUnauthenticated>());

      refreshCompleter.complete(session);
      await restoreFuture;

      expect(authCubit.state, isA<AuthUnauthenticated>());
      expect(authCubit.state, isNot(isA<AuthAuthenticated>()));

      verify(() => mockSessionManager.logout()).called(1);
    },
  );
}

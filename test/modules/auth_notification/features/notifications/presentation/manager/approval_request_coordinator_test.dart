import 'dart:async';

import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/device_verification_challenge.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/otp_challenge.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_state.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/domain/entities/approval_request.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_coordinator/approval_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_request_coordinator.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/pending_approval_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthCubit extends Mock implements AuthCubit {}

class MockApprovalCubit extends Mock implements ApprovalCubit {}


void main() {
  late MockAuthCubit authCubit;
  late MockApprovalCubit approvalCubit;
  late PendingApprovalManager pendingApprovalManager;
  late StreamController<AuthState> authController;
  late ApprovalRequestCoordinator coordinator;

  late AuthState currentAuthState;
  late List<ApprovalRequest> readyRequests;
  late Completer<void>? screenCloseCompleter;

  setUp(() {
    authCubit = MockAuthCubit();
    approvalCubit = MockApprovalCubit();

    pendingApprovalManager = PendingApprovalManager();
    authController = StreamController<AuthState>.broadcast(sync: true);

    currentAuthState = const AuthUnauthenticated();
    readyRequests = [];

    when(() => authCubit.state).thenAnswer((_) => currentAuthState);

    when(() => authCubit.stream).thenAnswer((_) => authController.stream);
    screenCloseCompleter = null;
    coordinator = ApprovalRequestCoordinator(
      authCubit: authCubit,
      approvalCubit: approvalCubit,
      pendingApprovalManager: pendingApprovalManager,
      onRequestReady: (request) async {
        readyRequests.add(request);
        await screenCloseCompleter?.future;
      },
    );
  });

  tearDown(() async {
    await coordinator.dispose();
    await authController.close();
  });

  group('ApprovalRequestCoordinator', () {
    test('stores deep link without fetching when user is unauthenticated', () {
      final accepted = coordinator.handleLink(
        Uri.parse('myapp://approval/request_001'),
      );

      expect(accepted, isTrue);
      expect(pendingApprovalManager.pendingRequestId, 'request_001');
      expect(readyRequests, isEmpty);

      verifyNever(
        () => approvalCubit.fetchRequest(requestId: any(named: 'requestId')),
      );
    });

    test('keeps pending request during OTP verification', () async {
      const request = ApprovalRequest(
        requestId: 'request_001',
        title: 'New Shop Approval',
        description: 'A new shop is waiting for your approval.',
      );

      when(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).thenAnswer((_) async => request);

      currentAuthState = const AuthOtpRequired(
        OtpChallenge(
          challengeId: 'otp_001',
          maskedDestination: 'u***@example.com',
        ),
      );

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      await Future<void>.delayed(Duration.zero);

      expect(pendingApprovalManager.pendingRequestId, 'request_001');
      expect(readyRequests, isEmpty);

      verifyNever(
        () => approvalCubit.fetchRequest(requestId: any(named: 'requestId')),
      );

      currentAuthState = const AuthAuthenticated();
      authController.add(currentAuthState);

      await Future<void>.delayed(Duration.zero);

      expect(readyRequests, [request]);
      expect(pendingApprovalManager.hasPendingRequest, isFalse);

      verify(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).called(1);
    });

    test('keeps pending request during device verification', () async {
      const request = ApprovalRequest(
        requestId: 'request_001',
        title: 'New Shop Approval',
        description: 'A new shop is waiting for your approval.',
      );

      when(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).thenAnswer((_) async => request);

      currentAuthState = const AuthDeviceVerificationRequired(
        DeviceVerificationChallenge(
          challengeId: 'device_001',
          deviceName: 'Windows Desktop',
        ),
      );

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      await Future<void>.delayed(Duration.zero);

      expect(pendingApprovalManager.pendingRequestId, 'request_001');
      expect(readyRequests, isEmpty);

      verifyNever(
        () => approvalCubit.fetchRequest(requestId: any(named: 'requestId')),
      );

      currentAuthState = const AuthAuthenticated();
      authController.add(currentAuthState);

      await Future<void>.delayed(Duration.zero);

      expect(readyRequests, [request]);
      expect(pendingApprovalManager.hasPendingRequest, isFalse);

      verify(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).called(1);
    });

    test('fetches pending request when user becomes authenticated', () async {
      const request = ApprovalRequest(
        requestId: 'request_001',
        title: 'New Shop Approval',
        description: 'A new shop is waiting for your approval.',
      );

      when(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).thenAnswer((_) async => request);

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      currentAuthState = const AuthAuthenticated();
      authController.add(currentAuthState);

      await Future<void>.delayed(Duration.zero);

      expect(readyRequests, [request]);
      expect(pendingApprovalManager.hasPendingRequest, isFalse);

      verify(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).called(1);
    });

    test('does not fetch the same request twice while processing', () async {
      final completer = Completer<ApprovalRequest?>();

      when(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).thenAnswer((_) => completer.future);

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      currentAuthState = const AuthAuthenticated();
      authController.add(currentAuthState);

      await Future<void>.delayed(Duration.zero);

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      completer.complete(
        const ApprovalRequest(
          requestId: 'request_001',
          title: 'New Shop Approval',
          description: 'A new shop is waiting for your approval.',
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(readyRequests.length, 1);

      verify(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).called(1);
    });

    test(
      'allows the same request again after the previous screen closes',
      () async {
        const request = ApprovalRequest(
          requestId: 'request_001',
          title: 'New Shop Approval',
          description: 'A new shop is waiting for your approval.',
        );

        when(
          () => approvalCubit.fetchRequest(requestId: 'request_001'),
        ).thenAnswer((_) async => request);

        coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

        currentAuthState = const AuthAuthenticated();
        authController.add(currentAuthState);

        await Future<void>.delayed(Duration.zero);

        coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

        await Future<void>.delayed(Duration.zero);

        expect(readyRequests, [request, request]);
        expect(pendingApprovalManager.hasPendingRequest, isFalse);

        verify(
          () => approvalCubit.fetchRequest(requestId: 'request_001'),
        ).called(2);
      },
    );

    test(
      'processes the latest request when a new link arrives during fetch',
      () async {
        final firstCompleter = Completer<ApprovalRequest?>();
        final secondCompleter = Completer<ApprovalRequest?>();

        const firstRequest = ApprovalRequest(
          requestId: 'request_001',
          title: 'First Request',
          description: 'First description',
        );

        const secondRequest = ApprovalRequest(
          requestId: 'request_002',
          title: 'Second Request',
          description: 'Second description',
        );

        when(
          () => approvalCubit.fetchRequest(requestId: 'request_001'),
        ).thenAnswer((_) => firstCompleter.future);

        when(
          () => approvalCubit.fetchRequest(requestId: 'request_002'),
        ).thenAnswer((_) => secondCompleter.future);

        coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

        currentAuthState = const AuthAuthenticated();
        authController.add(currentAuthState);

        await Future<void>.delayed(Duration.zero);

        coordinator.handleLink(Uri.parse('myapp://approval/request_002'));

        firstCompleter.complete(firstRequest);

        await Future<void>.delayed(Duration.zero);

        expect(readyRequests, isEmpty);

        secondCompleter.complete(secondRequest);

        await Future<void>.delayed(Duration.zero);

        expect(readyRequests, [secondRequest]);
        expect(pendingApprovalManager.hasPendingRequest, isFalse);

        verify(
          () => approvalCubit.fetchRequest(requestId: 'request_001'),
        ).called(1);

        verify(
          () => approvalCubit.fetchRequest(requestId: 'request_002'),
        ).called(1);
      },
    );

    test('keeps pending request when fetching fails', () async {
      when(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).thenAnswer((_) async => null);

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      currentAuthState = const AuthAuthenticated();
      authController.add(currentAuthState);

      await Future<void>.delayed(Duration.zero);

      expect(readyRequests, isEmpty);
      expect(pendingApprovalManager.pendingRequestId, 'request_001');
      expect(pendingApprovalManager.hasPendingRequest, isTrue);

      verify(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).called(1);
    });

    test('does not deliver request when user logs out during fetch', () async {
      final completer = Completer<ApprovalRequest?>();

      const request = ApprovalRequest(
        requestId: 'request_001',
        title: 'New Shop Approval',
        description: 'A new shop is waiting for your approval.',
      );

      when(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).thenAnswer((_) => completer.future);

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      currentAuthState = const AuthAuthenticated();
      authController.add(currentAuthState);

      await Future<void>.delayed(Duration.zero);

      currentAuthState = const AuthUnauthenticated();
      authController.add(currentAuthState);

      completer.complete(request);

      await Future<void>.delayed(Duration.zero);

      expect(readyRequests, isEmpty);
      expect(pendingApprovalManager.pendingRequestId, 'request_001');

      verify(() => approvalCubit.reset()).called(1);
    });

    test(
      'retries pending request when user logs in again during fetch',
      () async {
        final firstCompleter = Completer<ApprovalRequest?>();
        final secondCompleter = Completer<ApprovalRequest?>();

        const request = ApprovalRequest(
          requestId: 'request_001',
          title: 'New Shop Approval',
          description: 'A new shop is waiting for your approval.',
        );

        var fetchCount = 0;

        when(
          () => approvalCubit.fetchRequest(requestId: 'request_001'),
        ).thenAnswer((_) {
          fetchCount++;

          if (fetchCount == 1) {
            return firstCompleter.future;
          }

          return secondCompleter.future;
        });

        coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

        currentAuthState = const AuthAuthenticated();
        authController.add(currentAuthState);

        await Future<void>.delayed(Duration.zero);

        currentAuthState = const AuthUnauthenticated();
        authController.add(currentAuthState);

        currentAuthState = const AuthAuthenticated();
        authController.add(currentAuthState);

        firstCompleter.complete(request);

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(fetchCount, 2);
        expect(readyRequests, isEmpty);

        secondCompleter.complete(request);

        await Future<void>.delayed(Duration.zero);

        expect(readyRequests, [request]);
        expect(pendingApprovalManager.hasPendingRequest, isFalse);
      },
    );

    test('rejects invalid deep links', () {
      final accepted = coordinator.handleLink(
        Uri.parse('https://example.com/request_001'),
      );

      expect(accepted, isFalse);
      expect(pendingApprovalManager.hasPendingRequest, isFalse);

      verifyNever(
        () => approvalCubit.fetchRequest(requestId: any(named: 'requestId')),
      );
    });
    test(
      'ignores duplicate notification while request screen is open',
      () async {
        final completer = Completer<ApprovalRequest?>();

        screenCloseCompleter = Completer<void>();

        const request = ApprovalRequest(
          requestId: 'request_001',
          title: 'New Shop Approval',
          description: 'A new shop is waiting for your approval.',
        );

        when(
          () => approvalCubit.fetchRequest(requestId: 'request_001'),
        ).thenAnswer((_) => completer.future);

        coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

        currentAuthState = const AuthAuthenticated();
        authController.add(currentAuthState);

        await Future<void>.delayed(Duration.zero);

        completer.complete(request);

        await Future<void>.delayed(Duration.zero);

        expect(readyRequests, [request]);

        final accepted = coordinator.handleLink(
          Uri.parse('myapp://approval/request_001'),
        );

        expect(accepted, isFalse);
        expect(readyRequests, [request]);

        screenCloseCompleter!.complete();

        await Future<void>.delayed(Duration.zero);

        verify(
          () => approvalCubit.fetchRequest(requestId: 'request_001'),
        ).called(1);
      },
    );
    test('processes a different request after current screen closes', () async {
      final firstCompleter = Completer<ApprovalRequest?>();
      final secondCompleter = Completer<ApprovalRequest?>();

      screenCloseCompleter = Completer<void>();

      const firstRequest = ApprovalRequest(
        requestId: 'request_001',
        title: 'First Request',
        description: 'First description',
      );

      const secondRequest = ApprovalRequest(
        requestId: 'request_002',
        title: 'Second Request',
        description: 'Second description',
      );

      when(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).thenAnswer((_) => firstCompleter.future);

      when(
        () => approvalCubit.fetchRequest(requestId: 'request_002'),
      ).thenAnswer((_) => secondCompleter.future);

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      currentAuthState = const AuthAuthenticated();
      authController.add(currentAuthState);

      await Future<void>.delayed(Duration.zero);

      firstCompleter.complete(firstRequest);

      await Future<void>.delayed(Duration.zero);

      expect(readyRequests, [firstRequest]);

      coordinator.handleLink(Uri.parse('myapp://approval/request_002'));

      screenCloseCompleter!.complete();

      await Future<void>.delayed(Duration.zero);

      expect(readyRequests, [firstRequest]);

      secondCompleter.complete(secondRequest);

      await Future<void>.delayed(Duration.zero);

      expect(readyRequests, [firstRequest, secondRequest]);

      verify(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).called(1);

      verify(
        () => approvalCubit.fetchRequest(requestId: 'request_002'),
      ).called(1);
    });
  });
}


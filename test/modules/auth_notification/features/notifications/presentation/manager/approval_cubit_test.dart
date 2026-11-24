import 'dart:async';

import 'package:gold_shop_app/modules/auth_notification/features/notifications/domain/entities/approval_request.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/domain/usecases/get_approval_request_usecase.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_coordinator/approval_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_coordinator/approval_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetApprovalRequestUseCase extends Mock
    implements GetApprovalRequestUseCase {}

void main() {
  late MockGetApprovalRequestUseCase mockUseCase;
  late ApprovalCubit approvalCubit;

  setUp(() {
    mockUseCase = MockGetApprovalRequestUseCase();

    approvalCubit = ApprovalCubit(getApprovalRequestUseCase: mockUseCase);
  });

  tearDown(() async {
    await approvalCubit.close();
  });

  test('emits loading then loaded when fetching request succeeds', () async {
    const request = ApprovalRequest(
      requestId: 'request_001',
      title: 'Test Request',
      description: 'Test Description',
    );

    when(
      () => mockUseCase(requestId: 'request_001'),
    ).thenAnswer((_) async => request);

    final expectation = expectLater(
      approvalCubit.stream,
      emitsInOrder([
        isA<ApprovalLoading>(),
        isA<ApprovalLoaded>().having(
          (state) => state.request,
          'request',
          same(request),
        ),
      ]),
    );

    final result = await approvalCubit.fetchRequest(requestId: 'request_001');

    await expectation;

    expect(result, same(request));

    verify(() => mockUseCase(requestId: 'request_001')).called(1);
  });

  test('emits loading then failure when fetching request fails', () async {
    when(
      () => mockUseCase(requestId: 'request_001'),
    ).thenThrow(Exception('Network error'));

    final expectation = expectLater(
      approvalCubit.stream,
      emitsInOrder([
        isA<ApprovalLoading>(),
        isA<ApprovalFailure>().having(
          (state) => state.message,
          'message',
          'تعذر تحميل طلب الموافقة.',
        ),
      ]),
    );

    final result = await approvalCubit.fetchRequest(requestId: 'request_001');

    await expectation;

    expect(result, isNull);

    verify(() => mockUseCase(requestId: 'request_001')).called(1);
  });

  test('reset invalidates ongoing request and allows a new request', () async {
    final firstRequestCompleter = Completer<ApprovalRequest>();
    final firstRequestStarted = Completer<void>();

    const firstRequest = ApprovalRequest(
      requestId: 'request_001',
      title: 'Old Request',
      description: 'Old Description',
    );

    const secondRequest = ApprovalRequest(
      requestId: 'request_002',
      title: 'New Request',
      description: 'New Description',
    );

    var callCount = 0;

    when(() => mockUseCase(requestId: any(named: 'requestId'))).thenAnswer((
      invocation,
    ) {
      callCount++;

      if (callCount == 1) {
        firstRequestStarted.complete();
        return firstRequestCompleter.future;
      }

      return Future.value(secondRequest);
    });

    final firstFuture = approvalCubit.fetchRequest(requestId: 'request_001');

    await firstRequestStarted.future;

    approvalCubit.reset();

    final secondResult = await approvalCubit.fetchRequest(
      requestId: 'request_002',
    );

    firstRequestCompleter.complete(firstRequest);

    final firstResult = await firstFuture;

    expect(secondResult, same(secondRequest));
    expect(firstResult, isNull);
    expect(approvalCubit.state, isA<ApprovalLoaded>());
    expect(
      (approvalCubit.state as ApprovalLoaded).request,
      same(secondRequest),
    );

    expect(callCount, 2);
  });

  test('ignores failure from an invalidated request', () async {
    final firstCompleter = Completer<ApprovalRequest>();
    final secondCompleter = Completer<ApprovalRequest>();
    final firstRequestStarted = Completer<void>();
    final secondRequestStarted = Completer<void>();

    const secondRequest = ApprovalRequest(
      requestId: 'request_002',
      title: 'New Request',
      description: 'New Description',
    );

    var callCount = 0;

    when(() => mockUseCase(requestId: any(named: 'requestId'))).thenAnswer((
      invocation,
    ) {
      callCount++;

      if (callCount == 1) {
        firstRequestStarted.complete();
        return firstCompleter.future;
      }

      secondRequestStarted.complete();
      return secondCompleter.future;
    });

    final firstFuture = approvalCubit.fetchRequest(requestId: 'request_001');

    await firstRequestStarted.future;

    approvalCubit.reset();

    final secondFuture = approvalCubit.fetchRequest(requestId: 'request_002');

    await secondRequestStarted.future;

    firstCompleter.completeError(Exception('Old request failed'));

    expect(await firstFuture, isNull);
    expect(approvalCubit.state, isA<ApprovalLoading>());

    secondCompleter.complete(secondRequest);

    expect(await secondFuture, same(secondRequest));
    expect(
      (approvalCubit.state as ApprovalLoaded).request,
      same(secondRequest),
    );
  });

  test(
    'old request completion does not unlock an active new request',
    () async {
      final firstCompleter = Completer<ApprovalRequest>();
      final secondCompleter = Completer<ApprovalRequest>();
      final firstStarted = Completer<void>();
      final secondStarted = Completer<void>();

      var callCount = 0;

      when(() => mockUseCase(requestId: any(named: 'requestId'))).thenAnswer((
        invocation,
      ) {
        callCount++;

        if (callCount == 1) {
          firstStarted.complete();
          return firstCompleter.future;
        }

        secondStarted.complete();
        return secondCompleter.future;
      });

      final firstFuture = approvalCubit.fetchRequest(requestId: 'request_001');

      await firstStarted.future;

      approvalCubit.reset();

      final secondFuture = approvalCubit.fetchRequest(requestId: 'request_002');

      await secondStarted.future;

      firstCompleter.complete(
        const ApprovalRequest(
          requestId: 'request_001',
          title: 'Old Request',
          description: 'Old Description',
        ),
      );

      expect(await firstFuture, isNull);

      final thirdResult = await approvalCubit.fetchRequest(
        requestId: 'request_003',
      );

      expect(thirdResult, isNull);
      expect(callCount, 2);

      secondCompleter.complete(
        const ApprovalRequest(
          requestId: 'request_002',
          title: 'New Request',
          description: 'New Description',
        ),
      );

      expect(await secondFuture, isNotNull);
    },
  );

  test('does not fetch request after cubit is closed', () async {
    await approvalCubit.close();

    final result = await approvalCubit.fetchRequest(requestId: 'request_001');

    expect(result, isNull);
    expect(approvalCubit.state, isA<ApprovalInitial>());
    verifyNever(() => mockUseCase(requestId: any(named: 'requestId')));
  });

  test('does not reset state after cubit is closed', () async {
    await approvalCubit.close();

    expect(() => approvalCubit.reset(), returnsNormally);

    expect(approvalCubit.state, isA<ApprovalInitial>());
  });

  test('does not emit state when cubit is closed during fetch', () async {
    final completer = Completer<ApprovalRequest>();
    final requestStarted = Completer<void>();

    when(() => mockUseCase(requestId: 'request_001')).thenAnswer((_) {
      requestStarted.complete();
      return completer.future;
    });

    final future = approvalCubit.fetchRequest(requestId: 'request_001');

    await requestStarted.future;

    await approvalCubit.close();

    completer.complete(
      const ApprovalRequest(
        requestId: 'request_001',
        title: 'Test Request',
        description: 'Test Description',
      ),
    );

    final result = await future;

    expect(result, isNull);
    expect(approvalCubit.state, isA<ApprovalLoading>());
  });
}

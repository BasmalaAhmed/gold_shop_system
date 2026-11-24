import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gold_shop_app/modules/auth_notification/core/api/api_request_executor.dart';
import 'package:gold_shop_app/modules/auth_notification/core/errors/api_exception.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/entities/session.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/repos/session_refresh_repo.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/repos/session_repo.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/session_manager.dart';

class MockSessionRepo extends Mock implements SessionRepo {}

class MockSessionRefreshRepo extends Mock implements SessionRefreshRepo {}

void main() {
  late MockSessionRepo mockSessionRepo;
  late MockSessionRefreshRepo mockRefreshRepo;
  late SessionManager sessionManager;
  late ApiRequestExecutor executor;

  final initialSession = Session(
    accessToken: 'old_access',
    refreshToken: 'old_refresh',
    expiresAt: DateTime.now().add(const Duration(minutes: 15)),
  );

  final refreshedSession = Session(
    accessToken: 'new_access',
    refreshToken: 'new_refresh',
    expiresAt: DateTime.now().add(const Duration(minutes: 30)),
  );

  setUp(() async {
    mockSessionRepo = MockSessionRepo();
    when(() => mockSessionRepo.clearSession()).thenAnswer((_) async {});
    mockRefreshRepo = MockSessionRefreshRepo();

    sessionManager = SessionManager(mockSessionRepo, mockRefreshRepo);

    executor = ApiRequestExecutor(sessionManager);

    when(
      () => mockSessionRepo.getSession(),
    ).thenAnswer((_) async => initialSession);

    await sessionManager.initialize();
  });

  test('executes request without refreshing when successful', () async {
    final result = await executor.execute<String>(
      request: (accessToken) async {
        expect(accessToken, 'old_access');
        return 'success';
      },
    );

    expect(result, 'success');

    verifyNever(
      () => mockRefreshRepo.refreshSession(
        refreshToken: any(named: 'refreshToken'),
      ),
    );
  });

  test('refreshes token once after 401 and retries request', () async {
    var attempts = 0;

    when(
      () => mockRefreshRepo.refreshSession(refreshToken: 'old_refresh'),
    ).thenAnswer((_) async => refreshedSession);

    when(
      () => mockSessionRepo.saveSession(refreshedSession),
    ).thenAnswer((_) async {});

    final result = await executor.execute<String>(
      request: (accessToken) async {
        attempts++;

        if (attempts == 1) {
          expect(accessToken, 'old_access');

          throw const ApiException(statusCode: 401, message: 'Unauthorized');
        }

        expect(accessToken, 'new_access');

        return 'success';
      },
    );

    expect(result, 'success');
    expect(attempts, 2);
    expect(sessionManager.currentSession, refreshedSession);

    verify(
      () => mockRefreshRepo.refreshSession(refreshToken: 'old_refresh'),
    ).called(1);
  });

  test('does not refresh token when server returns 403', () async {
    await expectLater(
      executor.execute<String>(
        request: (_) async {
          throw const ApiException(statusCode: 403, message: 'Forbidden');
        },
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          403,
        ),
      ),
    );

    verifyNever(
      () => mockRefreshRepo.refreshSession(
        refreshToken: any(named: 'refreshToken'),
      ),
    );
  });

  test('does not refresh again when retry also returns 401', () async {
    var attempts = 0;

    when(
      () => mockRefreshRepo.refreshSession(refreshToken: 'old_refresh'),
    ).thenAnswer((_) async => refreshedSession);

    when(
      () => mockSessionRepo.saveSession(refreshedSession),
    ).thenAnswer((_) async {});

    await expectLater(
      executor.execute<String>(
        request: (_) async {
          attempts++;

          throw const ApiException(statusCode: 401, message: 'Unauthorized');
        },
      ),
      throwsA(isA<ApiException>()),
    );

    expect(attempts, 2);

    verify(
      () => mockRefreshRepo.refreshSession(refreshToken: 'old_refresh'),
    ).called(1);
  });

  test('throws 401 without executing request when no session exists', () async {
    await sessionManager.logout();

    var requestExecuted = false;

    await expectLater(
      executor.execute<String>(
        request: (_) async {
          requestExecuted = true;
          return 'success';
        },
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(requestExecuted, isFalse);

    verifyNever(
      () => mockRefreshRepo.refreshSession(
        refreshToken: any(named: 'refreshToken'),
      ),
    );
  });
  test('ends session and does not retry request when refresh fails', () async {
    var requestAttempts = 0;

    when(
      () => mockRefreshRepo.refreshSession(
        refreshToken: initialSession.refreshToken,
      ),
    ).thenThrow(Exception('Refresh failed'));

    await expectLater(
      executor.execute<String>(
        request: (_) async {
          requestAttempts++;

          throw const ApiException(statusCode: 401, message: 'Unauthorized');
        },
      ),
      throwsA(isA<Exception>()),
    );

    expect(requestAttempts, 1);
    expect(sessionManager.currentSession, isNull);

    verify(
      () => mockRefreshRepo.refreshSession(
        refreshToken: initialSession.refreshToken,
      ),
    ).called(1);

    verify(() => mockSessionRepo.clearSession()).called(1);
  });

  test('uses one refresh for 10 concurrent requests and retries each once', () async {
  const requestCount = 10;

  final refreshCompleter = Completer<Session>();
  final allRequestsStarted = Completer<void>();

  var refreshCalls = 0;
  var initialAttempts = 0;

  when(
    () => mockRefreshRepo.refreshSession(
      refreshToken: initialSession.refreshToken,
    ),
  ).thenAnswer((_) {
    refreshCalls++;
    return refreshCompleter.future;
  });

  when(
    () => mockSessionRepo.saveSession(refreshedSession),
  ).thenAnswer((_) async {});

  final requests = List.generate(requestCount, (index) async {
    var attempts = 0;

    return executor.execute<String>(
      request: (accessToken) async {
        attempts++;

        if (attempts == 1) {
          initialAttempts++;

          if (initialAttempts == requestCount) {
            allRequestsStarted.complete();
          }

          expect(accessToken, 'old_access');

          throw const ApiException(
            statusCode: 401,
            message: 'Unauthorized',
          );
        }

        expect(attempts, 2);
        expect(accessToken, 'new_access');

        return 'success_$index';
      },
    );
  });

  await allRequestsStarted.future;

  expect(refreshCalls, 1);

  refreshCompleter.complete(refreshedSession);

  final results = await Future.wait(requests);

  expect(results.length, requestCount);
  expect(
    results,
    List.generate(requestCount, (index) => 'success_$index'),
  );

  expect(refreshCalls, 1);
  expect(initialAttempts, requestCount);
  expect(sessionManager.currentSession, refreshedSession);

  verify(
    () => mockRefreshRepo.refreshSession(
      refreshToken: initialSession.refreshToken,
    ),
  ).called(1);
});
}

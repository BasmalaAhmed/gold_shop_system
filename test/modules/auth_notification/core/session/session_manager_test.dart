import 'dart:async';
import 'package:gold_shop_app/modules/auth_notification/core/session/repos/session_refresh_repo.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/repos/session_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/entities/session.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/session_manager.dart';

class MockSessionRepo extends Mock implements SessionRepo {}

class MockSessionRefreshRepo extends Mock implements SessionRefreshRepo {}

void main() {
  late MockSessionRepo mockRepo;
  late SessionManager sessionManager;
  late MockSessionRefreshRepo mockRefreshRepo;

  final session = Session(
    accessToken: 'access_123',
    refreshToken: 'refresh_123',
    expiresAt: DateTime(2026, 11, 21, 18),
  );

  setUp(() {
    mockRepo = MockSessionRepo();
    mockRefreshRepo = MockSessionRefreshRepo();
    sessionManager = SessionManager(mockRepo, mockRefreshRepo);
  });

  test('loads session during initialization', () async {
    when(() => mockRepo.getSession()).thenAnswer((_) async => session);

    await sessionManager.initialize();

    expect(sessionManager.currentSession, session);
    expect(sessionManager.hasSession, isTrue);
  });

  test('clears session during logout', () async {
    when(() => mockRepo.getSession()).thenAnswer((_) async => session);

    when(() => mockRepo.clearSession()).thenAnswer((_) async {});

    await sessionManager.initialize();
    await sessionManager.logout();

    expect(sessionManager.currentSession, isNull);
    expect(sessionManager.hasSession, isFalse);

    verify(() => mockRepo.clearSession()).called(1);
  });

  test(
    'does not restore session if logout happens during initialization',
    () async {
      final completer = Completer<Session?>();

      when(() => mockRepo.getSession()).thenAnswer((_) => completer.future);

      when(() => mockRepo.clearSession()).thenAnswer((_) async {});

      final initialization = sessionManager.initialize();

      await sessionManager.logout();

      completer.complete(session);

      await initialization;

      expect(sessionManager.currentSession, isNull);
      expect(sessionManager.hasSession, isFalse);
    },
  );
  test('returns false when no session exists', () {
    expect(sessionManager.hasValidSession, isFalse);
  });

  test('returns true when session is not expired', () {
    final validSession = Session(
      accessToken: 'access_123',
      refreshToken: 'refresh_123',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );

    when(() => mockRepo.getSession()).thenAnswer((_) async => validSession);

    return sessionManager.initialize().then((_) {
      expect(sessionManager.hasValidSession, isTrue);
    });
  });

  test('returns false when session is expired', () async {
    final expiredSession = Session(
      accessToken: 'access_123',
      refreshToken: 'refresh_123',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    when(() => mockRepo.getSession()).thenAnswer((_) async => expiredSession);

    await sessionManager.initialize();

    expect(sessionManager.hasSession, isTrue);
    expect(sessionManager.hasValidSession, isFalse);
  });

  test('performs only one refresh for concurrent requests', () async {
    final completer = Completer<Session>();

    final expiredSession = Session(
      accessToken: 'old_access',
      refreshToken: 'old_refresh',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    final refreshedSession = Session(
      accessToken: 'new_access',
      refreshToken: 'new_refresh',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );

    when(() => mockRepo.getSession()).thenAnswer((_) async => expiredSession);

    when(
      () => mockRefreshRepo.refreshSession(refreshToken: 'old_refresh'),
    ).thenAnswer((_) => completer.future);

    when(() => mockRepo.saveSession(refreshedSession)).thenAnswer((_) async {});

    await sessionManager.initialize();

    final requests = List.generate(10, (_) => sessionManager.refreshSession());

    verify(
      () => mockRefreshRepo.refreshSession(refreshToken: 'old_refresh'),
    ).called(1);

    completer.complete(refreshedSession);

    final results = await Future.wait(requests);

    expect(results, everyElement(refreshedSession));
    expect(sessionManager.currentSession, refreshedSession);

    verify(() => mockRepo.saveSession(refreshedSession)).called(1);
  });

  test('does not restore session when logout happens during refresh', () async {
    final completer = Completer<Session>();

    final expiredSession = Session(
      accessToken: 'old_access',
      refreshToken: 'old_refresh',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    final refreshedSession = Session(
      accessToken: 'new_access',
      refreshToken: 'new_refresh',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );

    when(() => mockRepo.getSession()).thenAnswer((_) async => expiredSession);

    when(() => mockRepo.clearSession()).thenAnswer((_) async {});

    when(
      () => mockRefreshRepo.refreshSession(refreshToken: 'old_refresh'),
    ).thenAnswer((_) => completer.future);

    await sessionManager.initialize();

    final refreshFuture = sessionManager.refreshSession();

    await sessionManager.logout();

    completer.complete(refreshedSession);

    await expectLater(refreshFuture, throwsA(isA<StateError>()));

    expect(sessionManager.currentSession, isNull);
    expect(sessionManager.hasSession, isFalse);

    verifyNever(() => mockRepo.saveSession(refreshedSession));

    verify(() => mockRepo.clearSession()).called(1);
  });

  test(
    'does not emit refresh failure when logout happens during failed refresh',
    () async {
      final completer = Completer<Session>();
      final refreshError = Exception('Refresh failed');

      final expiredSession = Session(
        accessToken: 'old_access',
        refreshToken: 'old_refresh',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      when(() => mockRepo.getSession()).thenAnswer((_) async => expiredSession);

      when(() => mockRepo.clearSession()).thenAnswer((_) async {});

      when(
        () => mockRefreshRepo.refreshSession(refreshToken: 'old_refresh'),
      ).thenAnswer((_) => completer.future);

      await sessionManager.initialize();

      var failureEventCount = 0;

      final subscription = sessionManager.onRefreshFailure.listen((_) {
        failureEventCount++;
      });

      final refreshFuture = sessionManager.refreshSession();

      await sessionManager.logout();

      completer.completeError(refreshError);

      await expectLater(refreshFuture, throwsA(same(refreshError)));

      expect(sessionManager.currentSession, isNull);
      expect(failureEventCount, 0);

      await subscription.cancel();

      verify(() => mockRepo.clearSession()).called(1);
    },
  );

  test('clears session if logout happens during session saving', () async {
    final saveCompleter = Completer<void>();
    final saveStarted = Completer<void>();

    final expiredSession = Session(
      accessToken: 'old_access',
      refreshToken: 'old_refresh',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    final refreshedSession = Session(
      accessToken: 'new_access',
      refreshToken: 'new_refresh',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );

    when(() => mockRepo.getSession()).thenAnswer((_) async => expiredSession);

    when(() => mockRepo.saveSession(refreshedSession)).thenAnswer((_) {
      if (!saveStarted.isCompleted) {
        saveStarted.complete();
      }
      return saveCompleter.future;
    });

    when(() => mockRepo.clearSession()).thenAnswer((_) async {});

    when(
      () => mockRefreshRepo.refreshSession(refreshToken: 'old_refresh'),
    ).thenAnswer((_) async => refreshedSession);

    await sessionManager.initialize();

    final refreshFuture = sessionManager.refreshSession();

    await saveStarted.future;

    final refreshExpectation = expectLater(
      refreshFuture,
      throwsA(isA<StateError>()),
    );

    final logoutFuture = sessionManager.logout();

    saveCompleter.complete();

    await logoutFuture;
    await refreshExpectation;

    expect(sessionManager.currentSession, isNull);

    verify(() => mockRepo.clearSession()).called(1);
  });

  test('clears session when refresh fails', () async {
    final expiredSession = Session(
      accessToken: 'old_access',
      refreshToken: 'invalid_refresh',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    when(() => mockRepo.getSession()).thenAnswer((_) async => expiredSession);

    when(
      () => mockRefreshRepo.refreshSession(refreshToken: 'invalid_refresh'),
    ).thenThrow(Exception('Invalid refresh token'));

    when(() => mockRepo.clearSession()).thenAnswer((_) async {});

    await sessionManager.initialize();

    await expectLater(
      sessionManager.refreshSession(),
      throwsA(isA<Exception>()),
    );

    expect(sessionManager.currentSession, isNull);
    expect(sessionManager.hasSession, isFalse);

    verify(() => mockRepo.clearSession()).called(1);
  });

  test(
    'does not clear a new session when an old refresh finishes after login',
    () async {
      final saveCompleter = Completer<void>();
      final saveStarted = Completer<void>();

      final oldSession = Session(
        accessToken: 'old_access',
        refreshToken: 'old_refresh',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      final refreshedSession = Session(
        accessToken: 'refreshed_access',
        refreshToken: 'refreshed_refresh',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );

      final newLoginSession = Session(
        accessToken: 'login_access',
        refreshToken: 'login_refresh',
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      );

      when(() => mockRepo.getSession()).thenAnswer((_) async => oldSession);

      when(
        () => mockRefreshRepo.refreshSession(refreshToken: 'old_refresh'),
      ).thenAnswer((_) async => refreshedSession);

      when(() => mockRepo.saveSession(refreshedSession)).thenAnswer((_) {
        if (!saveStarted.isCompleted) {
          saveStarted.complete();
        }

        return saveCompleter.future;
      });

      when(
        () => mockRepo.saveSession(newLoginSession),
      ).thenAnswer((_) async {});

      await sessionManager.initialize();

      final refreshFuture = sessionManager.refreshSession();

      await saveStarted.future;

      final loginFuture = sessionManager.setSession(newLoginSession);

      saveCompleter.complete();

      await expectLater(refreshFuture, throwsA(isA<StateError>()));

      await loginFuture;

      expect(sessionManager.currentSession, newLoginSession);
      expect(sessionManager.hasSession, isTrue);
      expect(sessionManager.hasValidSession, isTrue);

      verify(() => mockRepo.saveSession(refreshedSession)).called(1);
      verify(() => mockRepo.saveSession(newLoginSession)).called(1);

      verifyNever(() => mockRepo.clearSession());
    },
  );
  test('emits refresh failure event when refresh fails', () async {
    final expiredSession = Session(
      accessToken: 'old_access',
      refreshToken: 'invalid_refresh',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    when(() => mockRepo.getSession()).thenAnswer((_) async => expiredSession);

    when(
      () => mockRefreshRepo.refreshSession(refreshToken: 'invalid_refresh'),
    ).thenThrow(Exception('Invalid refresh token'));

    when(() => mockRepo.clearSession()).thenAnswer((_) async {});

    await sessionManager.initialize();

    final failureEvent = sessionManager.onRefreshFailure.first;

    await expectLater(
      sessionManager.refreshSession(),
      throwsA(isA<Exception>()),
    );

    await failureEvent;

    expect(sessionManager.currentSession, isNull);

    verify(() => mockRepo.clearSession()).called(1);
  });
  test(
    'emits refresh failure event even when clearing session fails',
    () async {
      final expiredSession = Session(
        accessToken: 'old_access',
        refreshToken: 'invalid_refresh',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      final refreshError = Exception('Refresh failed');
      final storageError = Exception('Storage deletion failed');

      when(() => mockRepo.getSession()).thenAnswer((_) async => expiredSession);

      when(
        () => mockRefreshRepo.refreshSession(refreshToken: 'invalid_refresh'),
      ).thenThrow(refreshError);

      when(() => mockRepo.clearSession()).thenThrow(storageError);

      await sessionManager.initialize();

      var failureEventCount = 0;

      final failureEventCompleter = Completer<void>();

      final subscription = sessionManager.onRefreshFailure.listen((_) {
        failureEventCount++;

        if (!failureEventCompleter.isCompleted) {
          failureEventCompleter.complete();
        }
      });

      await expectLater(
        sessionManager.refreshSession(),
        throwsA(same(refreshError)),
      );

      await failureEventCompleter.future;

      expect(sessionManager.currentSession, isNull);
      expect(sessionManager.hasSession, isFalse);
      expect(failureEventCount, 1);

      await subscription.cancel();
    },
  );
}

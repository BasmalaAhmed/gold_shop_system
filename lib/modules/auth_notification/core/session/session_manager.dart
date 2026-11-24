import 'dart:async';

import 'package:gold_shop_app/modules/auth_notification/core/session/entities/session.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/repos/session_refresh_repo.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/repos/session_repo.dart';

class SessionManager {
  final SessionRepo sessionRepo;
  final SessionRefreshRepo sessionRefreshRepo;

  SessionManager(this.sessionRepo, this.sessionRefreshRepo);

  Session? _currentSession;
  Future<Session>? _refreshFuture;
  Future<void> _storageQueue = Future<void>.value();
  int _sessionVersion = 0;
  int _refreshOperationVersion = 0;
  Session? get currentSession => _currentSession;
  bool get hasSession => _currentSession != null;
  bool get hasValidSession {
    final session = _currentSession;

    if (session == null) return false;

    return !session.isExpired;
  }

  final StreamController<void> _refreshFailureController =
      StreamController<void>.broadcast();

  Stream<void> get onRefreshFailure => _refreshFailureController.stream;

  Future<void> _enqueueStorageOperation(Future<void> Function() operation) {
    final nextOperation = _storageQueue.then((_) => operation());

    _storageQueue = nextOperation.catchError((Object error) {});

    return nextOperation;
  }

  Future<void> initialize() async {
    final currentVersion = _sessionVersion;

    final session = await sessionRepo.getSession();

    if (currentVersion != _sessionVersion) return;

    _currentSession = session;
  }

  Future<void> setSession(Session session) async {
    final currentVersion = ++_sessionVersion;

    _refreshOperationVersion++;
    _refreshFuture = null;

    await _enqueueStorageOperation(() async {
      if (currentVersion != _sessionVersion) {
        throw StateError('Session changed before saving.');
      }

      await sessionRepo.saveSession(session);
    });

    if (currentVersion != _sessionVersion) {
      throw StateError('Session changed while saving.');
    }

    _currentSession = session;
  }

  Future<void> logout() async {
    _sessionVersion++;

    _refreshOperationVersion++;
    _refreshFuture = null;

    _currentSession = null;

    await _enqueueStorageOperation(() async {
      await sessionRepo.clearSession();
    });
  }

  Future<Session> refreshSession() {
    final existingRefresh = _refreshFuture;

    if (existingRefresh != null) {
      return existingRefresh;
    }

    final session = _currentSession;

    if (session == null) {
      throw StateError('Cannot refresh without an active session.');
    }

    final currentVersion = _sessionVersion;

    final operationVersion = ++_refreshOperationVersion;

    final refreshFuture = _performRefresh(
      session,
      currentVersion,
      operationVersion,
    );

    _refreshFuture = refreshFuture;

    return refreshFuture;
  }

  Future<Session> _performRefresh(
    Session session,
    int sessionVersion,
    int operationVersion,
  ) async {
    try {
      final newSession = await sessionRefreshRepo.refreshSession(
        refreshToken: session.refreshToken,
      );

      if (sessionVersion != _sessionVersion) {
        throw StateError('Session changed during token refresh.');
      }

      await _enqueueStorageOperation(() async {
        if (sessionVersion != _sessionVersion) {
          throw StateError('Session changed before saving refreshed session.');
        }
        await sessionRepo.saveSession(newSession);
      });

      if (sessionVersion != _sessionVersion) {
        throw StateError('Session changed during token refresh.');
      }

      _currentSession = newSession;

      return newSession;
    } catch (refreshError, stackTrace) {
      if (sessionVersion == _sessionVersion) {
        try {
          await logout();
        } catch (_) {
        } finally {
          _refreshFailureController.add(null);
        }
      }

      Error.throwWithStackTrace(refreshError, stackTrace);
    } finally {
      if (operationVersion == _refreshOperationVersion) {
        _refreshFuture = null;
      }
    }
  }
}

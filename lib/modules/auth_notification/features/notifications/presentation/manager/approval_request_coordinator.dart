import 'dart:async';

import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_state.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_coordinator/approval_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/pending_approval_manager.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/domain/entities/approval_request.dart';

class ApprovalRequestCoordinator {
  final AuthCubit authCubit;
  final ApprovalCubit approvalCubit;
  final PendingApprovalManager pendingApprovalManager;

  final Future<void> Function(ApprovalRequest request) onRequestReady;

  late final StreamSubscription<AuthState> _authSubscription;

  bool _isProcessing = false;
  bool _isDisposed = false;
  String? _activeRequestId;
  int _authStateVersion = 0;

  ApprovalRequestCoordinator({
    required this.authCubit,
    required this.approvalCubit,
    required this.pendingApprovalManager,
    required this.onRequestReady,
  }) {
    _authSubscription = authCubit.stream.listen(_onAuthStateChanged);

    if (authCubit.state is AuthAuthenticated) {
      _processPendingRequest();
    }
  }

  bool handleLink(Uri uri) {
    if (_isDisposed) return false;

    final accepted = pendingApprovalManager.handleLink(
      uri,
      ignoredRequestId: _activeRequestId,
    );

    if (accepted) {
      _processPendingRequest();
    }

    return accepted;
  }

  void _onAuthStateChanged(AuthState state) {
    _authStateVersion++;

    if (state is AuthAuthenticated) {
      _processPendingRequest();
    }
  }

  Future<void> _processPendingRequest() async {
    if (_isDisposed || _isProcessing) return;

    if (authCubit.state is! AuthAuthenticated) return;

    if (!pendingApprovalManager.hasPendingRequest) return;

    _isProcessing = true;

    bool shouldRetryAfterAuthChange = false;

    try {
      while (!_isDisposed &&
          authCubit.state is AuthAuthenticated &&
          pendingApprovalManager.hasPendingRequest) {
        final requestId = pendingApprovalManager.pendingRequestId!;

        final authVersion = _authStateVersion;

        final request = await approvalCubit.fetchRequest(requestId: requestId);

        if (authVersion != _authStateVersion) {
          approvalCubit.reset();
          shouldRetryAfterAuthChange = true;
          return;
        }

        if (_isDisposed) return;

        if (authCubit.state is! AuthAuthenticated) {
          approvalCubit.reset();
          return;
        }

        if (pendingApprovalManager.pendingRequestId != requestId) {
          continue;
        }

        if (request == null) return;

        pendingApprovalManager.clearPendingRequest();

        _activeRequestId = requestId;

        try {
          await onRequestReady(request);
        } finally {
          if (_activeRequestId == requestId) {
            _activeRequestId = null;
          }

          approvalCubit.reset();
        }
      }
    } finally {
      _isProcessing = false;

      if (shouldRetryAfterAuthChange &&
          !_isDisposed &&
          authCubit.state is AuthAuthenticated &&
          pendingApprovalManager.hasPendingRequest) {
        unawaited(_processPendingRequest());
      }
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
    await _authSubscription.cancel();
  }
}

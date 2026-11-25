import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_shop_app/app/main_shell.dart';
import 'package:gold_shop_app/app/unified_dependencies.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/session_manager.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_state.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/views/device_verification_view.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/views/login_view.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/views/otp_view.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_coordinator/approval_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_coordinator/approval_state.dart';

class UnifiedAuthGate extends StatefulWidget {
  final SessionManager sessionManager;
  final bool Function(Uri uri) onDeepLink;
  final UnifiedDependencies dependencies;

  const UnifiedAuthGate({
    super.key,
    required this.sessionManager,
    required this.onDeepLink,
    required this.dependencies,
  });

  @override
  State<UnifiedAuthGate> createState() => _UnifiedAuthGateState();
}

class _UnifiedAuthGateState extends State<UnifiedAuthGate> {
  AuthState _lastStableState = const AuthInitial();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is! AuthLoading && state is! AuthInitial) {
          _lastStableState = state;
        }
        if (state is AuthUnauthenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      builder: (context, state) {
        final currentState = state is AuthLoading ? _lastStableState : state;

        if (currentState is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (currentState is AuthUnauthenticated ||
            currentState is AuthFailure) {
          return const LoginView();
        }

        if (currentState is AuthOtpRequired) {
          return OtpView(challenge: currentState.challenge);
        }

        if (currentState is AuthDeviceVerificationRequired) {
          return DeviceVerificationView(challenge: currentState.challenge);
        }

        if (currentState is AuthAuthenticated) {
          return Stack(
            children: [
              UnifiedMainShell(
                dependencies: widget.dependencies,
                onDeepLink: widget.onDeepLink,
              ),
              BlocBuilder<ApprovalCubit, ApprovalState>(
                builder: (context, approvalState) {
                  if (approvalState is ApprovalLoading) {
                    return const ColoredBox(
                      color: Colors.black26,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

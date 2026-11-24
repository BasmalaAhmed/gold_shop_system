import 'package:app_links/app_links.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/session_manager.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/views/device_verification_view.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/views/home_view.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/views/login_view.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/views/otp_view.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_coordinator/approval_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_coordinator/approval_state.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/widgets/approval_request_coordinator_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_shop_app/modules/auth_notification/core/app_dependencies.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_state.dart';

class AuthNotificationApp extends StatelessWidget {
  final AppDependencies dependencies;
  final AppLinks appLinks;

  const AuthNotificationApp({
    super.key,
    required this.dependencies,
    required this.appLinks,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => dependencies.createAuthCubit()..restoreSession(),
        ),
        BlocProvider(create: (_) => dependencies.createApprovalCubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Auth Notification App',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D9488)),
        ),
        home: ApprovalRequestCoordinatorHost(
          appLinks: appLinks,
          pendingApprovalManager: dependencies.pendingApprovalManager,
          builder: (context, coordinator) {
            return AuthGate(
              sessionManager: dependencies.sessionManager,
              onDeepLink: coordinator.handleLink,
            );
          },
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  final SessionManager sessionManager;
  final bool Function(Uri uri) onDeepLink;

  const AuthGate({
    super.key,
    required this.sessionManager,
    required this.onDeepLink,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthState _lastStableState = const AuthInitial();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is! AuthLoading && state is! AuthInitial) {
          _lastStableState = state;
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
          return BlocBuilder<ApprovalCubit, ApprovalState>(
            builder: (context, approvalState) {
              if (approvalState is ApprovalLoading ||
                  approvalState is ApprovalLoaded) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return HomeView(
                sessionManager: widget.sessionManager,
                onDeepLink: widget.onDeepLink,
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

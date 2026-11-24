import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gold_shop_app/app/auth_gate.dart';
import 'package:gold_shop_app/app/unified_dependencies.dart';
import 'package:gold_shop_app/core/unified_theme.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/widgets/approval_request_coordinator_host.dart';
import 'package:gold_shop_app/modules/shop_approval/core/connectivity/connectivity_cubit.dart';
import 'package:gold_shop_app/modules/shop_approval/features/approvals/presentation/manager/approval_requests_cubit/approval_requests_cubit.dart';

class UnifiedGoldShopApp extends StatefulWidget {
  final UnifiedDependencies dependencies;

  const UnifiedGoldShopApp({super.key, required this.dependencies});

  @override
  State<UnifiedGoldShopApp> createState() => _UnifiedGoldShopAppState();
}

class _UnifiedGoldShopAppState extends State<UnifiedGoldShopApp> {
  @override
  void dispose() {
    unawaited(widget.dependencies.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              widget.dependencies.authDependencies.createAuthCubit()
                ..restoreSession(),
        ),
        BlocProvider(
          create: (_) =>
              widget.dependencies.authDependencies.createApprovalCubit(),
        ),
        BlocProvider(
          create: (_) =>
              ConnectivityCubit(widget.dependencies.approvalConnectivity),
        ),
        BlocProvider(
          create: (_) => ApprovalRequestsCubit(
            widget.dependencies.approvalApi,
            isOnline: () => widget.dependencies.approvalConnectivity.isOnline,
          )..loadRequests(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'نظام إدارة محلات الذهب',
        theme: UnifiedTheme.lightTheme,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ApprovalRequestCoordinatorHost(
          appLinks: widget.dependencies.appLinks,
          pendingApprovalManager:
              widget.dependencies.authDependencies.pendingApprovalManager,
          builder: (context, coordinator) {
            return UnifiedAuthGate(
              sessionManager:
                  widget.dependencies.authDependencies.sessionManager,
              onDeepLink: coordinator.handleLink,
              dependencies: widget.dependencies,
            );
          },
        ),
      ),
    );
  }
}
